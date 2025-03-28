Introduction
======

Sproto is an efficient serialization library for C, and focuses on lua binding. It's like Google protocol buffers, but much faster.

The design is simple. It only supports a few types that lua supports. It can be easily bound to other dynamic languages, or be used directly in C.

In my i5-2500 @3.3GHz CPU, the benchmark is below:

The schema in sproto:

```
.Person {
    name 0 : string
    id 1 : integer
    email 2 : string

    .PhoneNumber {
        number 0 : string
        type 1 : integer
    }

    phone 3 : *PhoneNumber
}

.AddressBook {
    person 0 : *Person
}
```

It's equal to:

```
message Person {
  required string name = 1;
  required int32 id = 2;
  optional string email = 3;

  message PhoneNumber {
    required string number = 1;
    optional int32 type = 2 ;
  }

  repeated PhoneNumber phone = 4;
}

message AddressBook {
  repeated Person person = 1;
}
```

Use the data:
```lua
local ab = {
    person = {
        {
            name = "Alice",
            id = 10000,
            phone = {
                { number = "123456789" , type = 1 },
                { number = "87654321" , type = 2 },
            }
        },
        {
            name = "Bob",
            id = 20000,
            phone = {
                { number = "01234567890" , type = 3 },
            }
        }
    }
}
```

library| encode 1M times | decode 1M times | size
-------| --------------- | --------------- | ----
sproto | 2.15s           | 7.84s           | 83 bytes
sproto (nopack) |1.58s   | 6.93s           | 130 bytes
pbc-lua	  | 6.94s        | 16.9s           | 69 bytes
lua-cjson | 4.92s        | 8.30s           | 183 bytes

* pbc-lua is a google protocol buffers library https://github.com/cloudwu/pbc
* lua-cjson is a json library https://github.com/efelix/lua-cjson

Parser
=======

```lua
local parser = require "sprotoparser"
```

* `parser.parse` parses a sproto schema to a binary string.

The parser is needed for parsing the sproto schema. You can use it to generate binary string offline. The schema text and the parser is not needed when your program is running.

Lua API
=======

```lua
local sproto = require "sproto"
local sprotocore = require "sproto.core" -- optional
```

* `sproto.new(spbin)` creates a sproto object by a schema binary string (generates by parser).
* `sprotocore.newproto(spbin)` creates a sproto c object by a schema binary string (generates by parser).
* `sproto.sharenew(spbin)` share a sproto object from a sproto c object (generates by sprotocore.newproto).
* `sproto.parse(schema)` creates a sproto object by a schema text string (by calling parser.parse)
* `sproto:exist_type(typename)` detect whether a type exist in sproto object.
* `sproto:encode(typename, luatable)` encodes a lua table with typename into a binary string.
* `sproto:decode(typename, blob [,sz])` decodes a binary string generated by sproto.encode with typename. If blob is a lightuserdata (C ptr), sz (integer) is needed.
* `sproto:pencode(typename, luatable)` The same with sproto:encode, but pack (compress) the results.
* `sproto:pdecode(typename, blob [,sz])` The same with sproto.decode, but unpack the blob (generated by sproto:pencode) first.
* `sproto:default(typename, type)` Create a table with default values of typename. Type can be nil , "REQUEST", or "RESPONSE".

RPC API
=======

There is a lua wrapper for the core API for RPC .

`sproto:host([packagename])` creates a host object to deliver the rpc message.

`host:dispatch(blob [,sz])` unpack and decode (sproto:pdecode) the binary string with type the host created (packagename). 

If .type is exist, it's a REQUEST message with .type , returns "REQUEST", protoname, message, responser, .ud. The responser is a function for encode the response message. The responser will be nil when .session is not exist.

If .type is not exist, it's a RESPONSE message for .session . Returns "RESPONSE", .session, message, .ud .

`host:attach(sprotoobj)` creates a function(protoname, message, session, ud) to pack and encode request message with sprotoobj.

If you don't want to use host object, you can also use these following apis to encode and decode the rpc message:

`sproto:request_encode(protoname, tbl)` encode a request message with protoname.

`sproto:response_encode(protoname, tbl)` encode a response message with protoname.

`sproto:request_decode(protoname, blob [,sz])` decode a request message with protoname.

`sproto:response_decode(protoname, blob [,sz]` decode a response message with protoname.

Read testrpc.lua for detail.

Schema Language
==========

Like Protocol Buffers (but unlike json), sproto messages are strongly-typed and are not self-describing. You must define your message structure in a special language.

You can use sprotoparser library to parse the schema text to a binary string, so that the sproto library can use it. 
You can parse them offline and save the string, or you can parse them during your program running.

The schema text is like this:

```
# This is a comment.

.Person {	# . means a user defined type 
    name 0 : string	# string is a build-in type.
    id 1 : integer
    email 2 : string

    .PhoneNumber {	# user defined type can be nest.
        number 0 : string
        type 1 : integer
    }

    phone 3 : *PhoneNumber	# *PhoneNumber means an array of PhoneNumber.
    height 4 : integer(2)	# (2) means a 1/100 fixed-point number.
    data 5 : binary		# Some binary data
    weight 6 : double   # floating number
}

.AddressBook {
    person 0 : *Person(id)	# (id) is optional, means Person.id is main index.
}

foobar 1 {	# define a new protocol (for RPC used) with tag 1
    request Person	# Associate the type Person with foobar.request
    response {	# define the foobar.response type
        ok 0 : boolean
    }
}

```

A schema text can be self-described by the sproto schema language.

```
.type {
    .field {
        name 0 : string
        buildin	1 : integer
        type 2 : integer	# type is fixed-point number precision when buildin is SPROTO_TINTEGER; When buildin is SPROTO_TSTRING, it means binary string when type is 1.
        tag 3 : integer
        array 4	: boolean
        key 5 : integer # If key exists, array must be true, and it's a map.
    }
    name 0 : string
    fields 1 : *field
}

.protocol {
    name 0 : string
    tag 1 : integer
    request 2 : integer # index
    response 3 : integer # index
    confirm 4 : boolean # response nil where confirm == true
}

.group {
    type 0 : *type
    protocol 1 : *protocol
}
```

Types
=======

* **string** : string
* **binary** : binary string (it's a sub type of string)
* **integer** : integer, the max length of an integer is signed 64bit. It can be a fixed-point number with specified precision.
* **double** : double precision floating-point number, satisfy [the IEEE 754 standard](https://en.wikipedia.org/wiki/Double-precision_floating-point_format).
* **boolean** : true or false

You can add * before the typename to declare an array.

You can also specify a main index with the syntax likes `*array(id)`, the array would be encode as an unordered map with the `id` field as key.

For empty main index likes `*array()`, the array would be encoded as an unordered map with the first field as key and the second field as value.

User defined type can be any name in alphanumeric characters except the build-in typenames, and nested types are supported.

* Where are double or real types?

I have been using Google protocol buffers for many years in many projects, and I found the real types were seldom used. If you really need it, you can use string to serialize the double numbers. When you need decimal, you can specify the fixed-point precision.

**NOTE** : `double` is supported now.

* Where is enum?

In lua, enum types are not very useful. You can use integer to define an enum table in lua.

Wire protocol
========

Each integer number must be serialized in little-endian format.

The sproto message must be a user defined type struct, and a struct is encoded in three parts. The header, the field part, and the data part. 
The tag and small integer or boolean will be encoded in field part, and others are in data part.

All the fields must be encoded in ascending order (by tag, base 0). The tags of fields can be discontinuous, if a field is nil. (default value in lua), don't encode it in message.

The header is a 16bit integer. It is the number of fields.

Each field in field part is a 16bit integer (n). If n is zero, that means the field data is encoded in data part ;

If n is even (and not zero), the value of this field is n/2-1 , and the tag increases 1;

If n is odd, that means the tags is not continuous, and we should add current tag by (n+1)/2 .

Arrays are always encode in data part, 4 bytes header for the size, and the following bytes is the contents. See the example 2 for the struct array; example 3/4 for the integer array ; example 5 for the boolean array.

For integer array, an additional byte (4 or 8) to indicate the value is 32bit or 64bit.

Read the examples below to see more details.

Notice: If the tag is not declared in schema, the decoder will simply ignore the field for protocol version compatibility.
Notice more: all examples are tested in `test_wire_protocol.lua`, update `test_wire_protocol.lua` when update examples.

```
.Person {
    name 0 : string
    age 1 : integer
    marital 2 : boolean
    children 3 : *Person
}

.Data {
	numbers 0 : *integer
	bools 1 : *boolean
	number 2 : integer
	bignumber 3 : integer
 	double 4 : double
 	doubles 5 : *double
 	fpn 6 : integer(2)
}
```

Example 1:

```
person { name = "Alice" ,  age = 13, marital = false } 

03 00 (fn = 3)
00 00 (id = 0, value in data part)
1C 00 (id = 1, value = 13)
02 00 (id = 2, value = false)
05 00 00 00 (sizeof "Alice")
41 6C 69 63 65 ("Alice")
```

Example 2:

```
person {
    name = "Bob",
    age = 40,
    children = {
        { name = "Alice" ,  age = 13 },
        { name = "Carol" ,  age = 5 },
    }
}

04 00 (fn = 4)
00 00 (id = 0, value in data part)
52 00 (id = 1, value = 40)
01 00 (skip id = 2)
00 00 (id = 3, value in data part)

03 00 00 00 (sizeof "Bob")
42 6F 62 ("Bob")

26 00 00 00 (sizeof children)

0F 00 00 00 (sizeof child 1)
02 00 (fn = 2)
00 00 (id = 0, value in data part)
1C 00 (id = 1, value = 13)
05 00 00 00 (sizeof "Alice")
41 6C 69 63 65 ("Alice")

0F 00 00 00 (sizeof child 2)
02 00 (fn = 2)
00 00 (id = 0, value in data part)
0C 00 (id = 1, value = 5)
05 00 00 00 (sizeof "Carol")
43 61 72 6F 6C ("Carol")
```

Example 3:

```
data {
    numbers = { 1,2,3,4,5 }
}

01 00 (fn = 1)
00 00 (id = 0, value in data part)

15 00 00 00 (sizeof numbers)
04 ( sizeof int32 )
01 00 00 00 (1)
02 00 00 00 (2)
03 00 00 00 (3)
04 00 00 00 (4)
05 00 00 00 (5)
```

Example 4:
```
data {
    numbers = {
        (1<<32)+1,
        (1<<32)+2,
        (1<<32)+3,
    }
}

01 00 (fn = 1)
00 00 (id = 0, value in data part)

19 00 00 00 (sizeof numbers)
08 ( sizeof int64 )
01 00 00 00 01 00 00 00 ( (1<32) + 1)
02 00 00 00 01 00 00 00 ( (1<32) + 2)
03 00 00 00 01 00 00 00 ( (1<32) + 3)
```

Example 5:
```
data {
    bools = { false, true, false }
}

02 00 (fn = 2)
01 00 (skip id = 0)
00 00 (id = 1, value in data part)

03 00 00 00 (sizeof bools)
00 (false)
01 (true)
00 (false)
```

Example 6:
```
data {
    number = 100000,
    bignumber = -10000000000,
}

03 00 (fn = 3)
03 00 (skip id = 1)
00 00 (id = 2, value in data part)
00 00 (id = 3, value in data part)

04 00 00 00 (sizeof number, data part)
A0 86 01 00 (100000, 32bit integer)

08 00 00 00 (sizeof bignumber, data part)
00 1C F4 AB FD FF FF FF (-10000000000, 64bit integer)
```

Example 7:
```
data {
    double = 0.01171875,
    doubles = {0.01171875, 23, 4}
}

03 00 (fn = 3)
07 00 (skip id = 3)
00 00 (id = 4, value in data part)
00 00 (id = 5, value in data part)

08 00 00 00 (sizeof number, data part)
00 00 00 00 00 00 88 3f (0.01171875, 64bit double)

19 00 00 00 (sizeof doubles)
08 (sizeof double)
00 00 00 00 00 00 88 3f (0.01171875, 64bit double)
00 00 00 00 00 00 37 40 (23, 64bit double)
00 00 00 00 00 00 10 40 (4, 64bit double)
```

Example 8:
```
data {
    fpn = 1.82,
}

02 00 (fn = 2)
0b 00 (skip id = 5)
6e 01 (id = 6, value = 0x16e/2 - 1 = 182)
```

0 Packing
=======

The algorithm is very similar to [Cap'n proto](http://kentonv.github.io/capnproto/), but 0x00 is not treated specially. 

In packed format, the message is padding to 8. Each 8 byte is reduced to a tag byte followed by zero to eight content bytes. 
The bits of the tag byte correspond to the bytes of the unpacked word, with the least-significant bit corresponding to the first byte. 
Each zero bit indicates that the corresponding byte is zero. The non-zero bytes are packed following the tag.

For example:

```
unpacked (hex):  08 00 00 00 03 00 02 00   19 00 00 00 aa 01 00 00
packed (hex):  51 08 03 02   31 19 aa 01
```

Tag 0xff is treated specially. A number N is following the 0xff tag. N means (N+1)\*8 bytes should be copied directly. 
The bytes may or may not contain zeros. Because of this rule, the worst-case space overhead of packing is 2 bytes per 2 KiB of input.

For example:

```
unpacked (hex):  8a (x 30 bytes)
packed (hex):  ff 03 8a (x 30 bytes) 00 00
```

C API
=====

```C
struct sproto * sproto_create(const void * proto, size_t sz);
```

Create a sproto object with a schema string encoded by sprotoparser:

```C
void sproto_release(struct sproto *);
```

Release the sproto object:

```C
int sproto_prototag(struct sproto *, const char * name);
const char * sproto_protoname(struct sproto *, int proto);
// SPROTO_REQUEST(0) : request, SPROTO_RESPONSE(1): response
struct sproto_type * sproto_protoquery(struct sproto *, int proto, int what);
```

Convert between tag and name of a protocol, and query the type object of it:

```C
struct sproto_type * sproto_type(struct sproto *, const char * typename);
```

Query the type object from a sproto object:

```C
struct sproto_arg {
	void *ud;
	const char *tagname;
	int tagid;
	int type;
	struct sproto_type *subtype;
	void *value;
	int length;
	int index;	// array base 1
	int mainindex;	// for map
	int extra; // SPROTO_TINTEGER: fixed-point presision ; SPROTO_TSTRING 0:utf8 string 1:binary
};

typedef int (*sproto_callback)(const struct sproto_arg *args);

int sproto_decode(struct sproto_type *, const void * data, int size, sproto_callback cb, void *ud);
int sproto_encode(struct sproto_type *, void * buffer, int size, sproto_callback cb, void *ud);
```

encode and decode the sproto message with a user defined callback function. Read the implementation of lsproto.c for more details.

```C
int sproto_pack(const void * src, int srcsz, void * buffer, int bufsz);
int sproto_unpack(const void * src, int srcsz, void * buffer, int bufsz);
```

pack and unpack the message with the 0 packing algorithm.

Other Implementions and bindings
=====
See Wiki https://github.com/cloudwu/sproto/wiki

Question?
==========

* Send me an email: http://www.codingnow.com/2000/gmail.gif
* My Blog: http://blog.codingnow.com
* Design: http://blog.codingnow.com/2014/07/ejoyproto.html (in Chinese)
