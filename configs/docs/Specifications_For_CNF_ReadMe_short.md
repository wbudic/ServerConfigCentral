# Configuration Network File Format Specifications

## Introduction

This is a simple and fast file format. That allows setting up of network and database applications with initial configuration values.
These are usually standard, property name and value pairs. Containing possible also SQL database structures statements with basic data.
It is designed to accommodate a parser to read and provide for CNF property tags.

These can be of four types, using all a textual similar presentation.
In general are recognized as constants, anons, collections or lists, that are either arrays or hashes.

Operating system environmental settings or variables are considered only as the last resort to provide for a property value.
As these can hide and hold the unexpected value for a setting.

With the CNF type of an application configuration system. Global settings can also be individual scripted with an meaningful description.
Which is pretty much welcomed and encouraged. As the number of them can be quite large, and meanings and requirements, scattered around code comments or various documentation. Why not keep this information next to; where you also can set it.

CNF type tags are script based, parsed tags of text, everything else is ignored. DOM based parsed tags, require definitions and are hierarchy specific, path based. Even comments, have specified format. A complete different thing. However, in a CNF file you, can nest and tag, DOM based scripts. But not the other way. DOM based scripts are like HTML, XML. They might scream errors if you place in them CNF stuff.

## General CNF Formatting Rules

1. Text that isn't CNF tagged is ignored in the file and can be used as comments.
2. CNF tag begins with an **<<** or **<<<** and ends with an **>>>** or **>>**.
3. If instruction is contained the tag begins with **<<** and ends with a **>>**.
4. Multi line values are tag ended on a separate line with an **>>>**.
5. CNF tag value can post processed by placing macros making it a template.
6. Standard markup of a macro is to enclose the property name or number with a triple dollar signifier **\$\$\$**{macro}**\$\$\$**.
    1. Precedence of resolving the property name/value is by first passed macros, then config anons and finally the looking up constance's.
    2. Nested macros resolving from linked in other properties is currently not supported.
7. CNF full tag syntax format: **```<<{$|@|%}NAME{<INSTRUCTION>}{<any type of value>}>>```**, the name and instruction parts, sure open but don't have to be closed with **>** on a multiple line value.
8. CNF instructions and constants are uppercase.
    1. Example 1 format with instruction: ```<<<CONST\n{name=value\n..}\n>>>``` autonomous const, with inner properties.
    2. Example 2 format with instruction: ```<<{$sig}{NAME}<CONST {multi line value}>>>``` A single const property with a multi line value.
    3. Example 3 format with instruction: ```<<CONST<{$sig}{NAME}\n {multi line value}>>>``` A single const property with a multi line value.
    4. Example 4 format with instruction: ```<<{NAME}<{INSTRUCTION}<{value}>>>``` A anon.
    5. Example 5 format with instruction: ```<<{$sig}{NAME}<{INSTRUCTION}\n{value}\n>>>```.
9. CNF instructions are all uppercase and unique, to the processor.
10. A CNF constant in its property name is prefixed with an '**$**' signifier.
11. Constants are usually scripted at the beginning of the file, or parsed first in a separate file.
12. The instruction processor can use them if signifier $ surrounds the constant name. Therefore, replacing it with the constants value if further found in the file.
