import deques, strformat, strutils, streams, math

type
  StackItemKind = enum
    siNumber,        
    siList,      
  StackItem = ref object
    case kind: StackItemKind # the ``kind`` field is the discriminator
    of siNumber: numberVal: float
    of siList: listVal: seq[char]

# Implements echo/repr for our StackItem
proc `$`(si: StackItem): string =
  case si.kind:
  of siNumber:
    result = &"StackItem(siNumber, numberVal: {si.numberVal})"
  of siList:
    result = "StackItem(siList, listVal: @[" & si.listVal.join(", ") & "])"


# Initialize empty stack
# element [len(stack)] refers to the TOP of the stack
var stack = initDeque[StackItem]()

#for i in 1..5:
#  stack.addLast(StackItem(kind: siNumber, numberVal: i.toFloat))
#stack.addLast(StackItem(kind: siList, listVal: @[9.1, 9.2, 9.3]))

#var commandStream = "4 2-" # TODO: Initialize this from register a
var commandStream = newStringStream("423.15")
var operationMode: int = 0


#############
# Main loop #
#############
while true:

  var ch = readChar(commandStream)

  if ch == '\0':
    break

  case operationMode:
  # Decimal Place Construction Mode
  of low(int)..(-2):
    case ch:
    of '0'..'9':
      var top = popLast(stack)
      var a = top.numberVal + float((int(ch) - int('0'))) * pow(10, float(operationMode+1))

      top.numberVal = a
      addLast(stack, top)
      operationMode -= 1

    of '.':
      addLast(stack, StackItem(kind: siNumber, numberVal: float(0)))
      operationMode = -2
    else:
      operationMode = 0
      setPosition(commandStream, getPosition(commandStream)-1)

  # Whole Number Construction Mode
  of -1:
    case ch:
    of '0'..'9':
      var top = popLast(stack)

      var a = top.numberVal * 10 + float((int(ch) - int('0')))
      top.numberVal = a
      addLast(stack, top)

    of '.':
      operationMode = -2
    else:
      operationMode = 0
      setPosition(commandStream, getPosition(commandStream)-1)


  # Execution Mode
  of 0:
    case ch:
    of '0'..'9':
      var a = float((int(ch) - int('0')))
      addLast(stack, StackItem(kind: siNumber, numberval: a))
      operationMode = -1
    else:
      discard
  
  # List Construction Mode
  of 1..high(int):
    case ch:
    of '(':
      var top = popLast(stack)
      top.listVal.add('(')
      addLast(stack, top)
      operationMode += 1
    of ')':
      if operationMode > 1:
        var top = popLast(stack)
        top.listVal.add(')')
        addLast(stack, top)
      operationMode -= 1
    else:
      var top = popLast(stack)
      top.listVal.add(ch)
      addLast(stack, top)


echo stack
