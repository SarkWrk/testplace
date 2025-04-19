---
title: "Docs/GeneralLibrary"
permalink: /Archive/GeneralLibrary
description: "Documentation of my 'GeneralLibrary' module."
---

**Note: All numbers are in base 10.**

## \[module_name\].NumberManipulation.*

### **\*OrderOfMagnitude(number) → number**

### *Finds the order of magnitude of an inputted number.*

<br />

#### Overloads:

number\<number\> → The number to find the order of magnitude of.

#### Returns:

number\<number\> → The order of magnitude.

### **\*Rounder(number, number?) → number**

### *Rounds a number to a number of decimal places. Accepts a second overload to specify how many places toround to. NOTE: Attempting to round to a negative amount of decimal places can lead to unpredictable results and is not advised - however, it is possible.*

<br />

#### Overloads:

input\<number\> → The number to round.

places\<number?\> → How many places to round to. If left blank, rounds to no decimal places.

#### Returns:

number\<number\> → The rounded number.

### **\*Truncater(number, number) → (number, number)**

### *Truncates a number with the specified number of leading didgits. The returned number will be the leading didgits × e-1 and the order of magnitude of the original number.*

<br />

#### Overloads:

number\<number\> → Number to be truncated.

places\<number\> → How many places to truncate to.

#### Returns:

number1\<number\> → The truncated number.

***Note:** This number is returned as ... × **10^-1**.*

<br />

number2\<number> → The order of magnitude of the number.

### **\*Delta(number|Vector3, number|Vector3) → number**

### *Finds the difference (delta) between two numbers OR two Vector3s. Both types much match in order to function.*

#### Overloads:

initial\<number|Vector3> → The starting position used.

final\<number|Vector3!> → The final position used.

#### Returns:

number\<number\> → The difference of the two numbers. If the initial types are Vector3s, this is always a positive value.

<hr>

## \[module_name\].Conversions.*

### **\*StringToVector3(string, string) → Vector3**

### *Converts a character/string seperated string into a Vector3. NOTE: The first overload should be formatted as x\[seperator\]y\[seperator\]z.*

<br />

#### Overloads:

stringEquivilant\<string\> → To string version of the Vector3.

seperator\<string\> → The seperator between each chordinate value.

#### Returns:

Vector3\<Vector3\> → The Vector3 spliced together from stringEquivilant and seperator.

### **\*Vector3ToCFrame(Vector3, Vector3?) → CFrame**

### *Converts one or two Vector3s to a CFrame. The first Vector3 is used as the positional component of the CFrame, and the second Vector3 is used for the rotational component of the  CFrame. The second Vector3 can be left blank to keep the rotation of the resulting CFrame (0, 0, 0).*

<br />

#### Overloads:

position\<Vector3\> → The Vector3 that is used for the positional component of the returned CFrame. (CFrame.new(position.X, position.Y, position.Z).)

rotation\<Vector3?\> → The Vector3 that is used for the rotational component of the returned CFrame. (CFrame.Angles(rotation.X, rotation.Y, rotation.Z).)

#### Returns:

CFrame\<CFrame\> → A CFrame with the position of position and rotation of rotation.

### **\*Vector3ToString(Vector3, string, boolean?, number?) → string**

### *Converts a Vector3 to a string using a seperator (second overload). The returned string is formatted as "Vector3.X\[string\]Vector3.Y\[string\]Vector3.Z". The third overload can be filled in to round the components of the Vector3. The fourth overload can be filled in to specify to how many places.*

<br />

#### Overloads:

vector\<Vector3\> → The Vector3 that should be turned into a string.

seperator\<string\> → The string used to seperate the components of vector.

round\<boolean?\> → Whether vector's components should be rounded.

places\<number?\> → How many places vector's components should be rounded to. If left blank, rounds to the nearest integer.

#### Returns:

string\<string\> → A string formatted as "vector.X\[seperator\]vector.Y\[seperator\]vector.Z".

### **\*CFrameAnglesToVector3(CFrame, boolean?, number?) → Vector3**
### *Converts the rotation of a CFrame into a Vector3. The second overload can be filled in to specify if the rotation should be rounded. The third overload can be filled in to specify to how many places each component should be rounded to.*

<br />

#### Overloads:

converted\<CFrame\> → The CFrame who's rotation should be taken from.

round\<boolean?\> → Whether the components of converted's rotation should be rounded.

places\<number?\> → How many places to round each component to.

#### Returns:

Vector3\<Vector3\> → A Vector3 where the X component corresponds to converted's X rotational component, the Y component corresponds to converted's Y rotational component, and the Z component corresponds to converted's Z rotational component.

<hr>

## \[module_name\].TableManipulation.*

### **\*.CreateRelativeTable({[number] : Vector3}, Vector3?) → {[number] : {[number] : {Distance : number, Index : number}}}**
### **

***NOTE:** The distances calculated between each point uses \*.NumberConversions.Delta(). If the calculated distance is incorrect, it is most likely because Delta() is wrong, or the points that are inputted are incorrect.*

<br />

#### Inputs:

tableOfPositions\<{}\> → A table of index-based positions.

startPoint\<Vector3?\> → Whether to insert a point into tableOfPositions as the starting point of the table.

***Note:** This value will be inserted into tableOfPositions at index 1, shifting all other values down by one before any calculations start.*

#### Returns:

{[number] : {[number] : {Distance : number, Index : number}}}\<{}\> → A table with subtables who's subtables contain the distance between the current index's point and another index's point, with index refering to the index of the other point.

### **\*.OrderRelativeTable({[number] : {[number] : {Distance : number, Index : number}}}) → {[number] : {Distance : number, Index : number}}**
### *Orders a list based off which next distance is closest to the previous index starting at index 1. Check the inputs to see how this list must be formatted.*

<br />

#### Inputs:

tableOfRelativeDistances\<{}\> → The list who's order should be found.

***NOTE:** This table has to be formatted as: {[number1] = {[number2] = {Distance = number, Index = number2}}} where number2 is the index in the dictionary from where the distance is calculated from. This format is the exact same as the one that is returned by \*.TableManipulation.CreateRelativeTable().*

#### Returns:

{[number] : {Distance : number, Index : number}}\<{}\> → The ordered list of groups based off the relative distances between each point starting at index 1 of tableOfRelativeDistances. Each subgroup contains two values: "Distance" and "Index". Distance is the distance between the current point and the next point, and Index is the next point.