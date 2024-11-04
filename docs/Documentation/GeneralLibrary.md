---
title: "Docs/GeneralLibrary"
permalink: /GeneralLibrary
description: "Documentation of my 'GeneralLibrary' module."
---

**Note:**

**All numbers are in base 10.**

## Functions:

<hr>

### module.NumberManipulation.*

> **\*OrderOfMagnitude(number) → number**

>*Finds the order of magnitude of an inputted number.*

Inputs:

number\<number\> → The number to find the order of magnitude of.

Returns:

number\<number\> → The order of magnitude.

> **\*Rounder(number, number?) → number**

>*Rounds a number to a number of decimal places. Accepts a second overload to specify how many places toround to.*

Inputs:

input\<number\> → The number to round.

places\<number?\> → How many places to round to. If left blank, rounds to no decimal places.

Returns:

number\<number\> → The rounded number.

> **\*Truncater(number, number) → (number, number)**

>*Truncates a number with the specified number of leading didgits. The returned number will be the leading didgits × e-1 and the order of magnitude of the original number.*

Inputs:

number\<number\> → Number to be truncated.

places\<number\> → How many places to truncate to.

Returns:

number1\<number\> → The truncated number. ***Note:** This number is returned as ... × **10^-1.***

number2\<number> → The order of magnitude of the number.

> **\*Delta(number|Vector3, number|Vector3) → number**

>*Finds the difference (delta) between two numbers OR two Vector3s. Both types much match in order to function.*

Inputs:

initial\<number|Vector3> → The starting position used.

final\<number|Vector3!> → The final position used.

Returns:

number\<number\> → The difference of the two numbers. If the initial types are Vector3s, this is always a positive value.

<hr>

### Conversions

> **\*StringToVector3(string, string) → Vector3**

>*Converts a character/string seperated string into a Vector3. NOTE: The first overload should be formatted as x\[seperator\]y\[seperator\]z.*

Inputs:

stringEquivilant\<string\> → To string version of the Vector3.

seperator\<string\> → The seperator between each chordinate value.

Returns:

Vector3\<Vector3\> → The Vector3 spliced together from stringEquivilant and seperator.

> **\*Vector3ToCFrame(Vector3, Vector3?) → CFrame**

>*Converts one or two Vector3s to a CFrame. The first Vector3 is used as the positional component of the CFrame, and the second Vector3 is used for the rotational component of the  CFrame. The second Vector3 can be left blank to keep the rotation of the resulting CFrame (0, 0, 0).*

Inputs:

position\<Vector3\> → The Vector3 that is used for the positional component of the returned CFrame. (CFrame.new(position.X, position.Y, position.Z).)

rotation\<Vector3?\> → The Vector3 that is used for the rotational component of the returned CFrame. (CFrame.Angles(rotation.X, rotation.Y, rotation.Z).)

Returns:

CFrame\<CFrame\> → A CFrame with the position of position and rotation of rotation.

> **\*Vector3ToString(Vector3, string, boolean?, number?) → string**

>*Converts a Vector3 to a string using a seperator (second overload). The returned string is formatted as "Vector3.X\[string\]Vector3.Y\[string\]Vector3.Z". The third overload can be filled in to round the components of the Vector3. The fourth overload can be filled in to specify to how many places.*

Inputs:

vector\<Vector3\> → The Vector3 that should be turned into a string.

seperator\<string\> → The string used to seperate the components of vector.

round\<boolean?\> → Whether vector's components should be rounded.

places\<number?\> → How many places vector's components should be rounded to. If left blank, rounds to the nearest integer.

Returns:

string\<string\> → A string formatted as "vector.X\[seperator\]vector.Y\[seperator\]vector.Z".