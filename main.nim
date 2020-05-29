import deques, strformat, strutils, streams, math

# Used for comparisons
let epsilon = 5.96e-08

type
  StackItemKind = enum
    siNumber,        
    siList,      
  StackItem = ref object
    case kind: StackItemKind # the ``kind`` field is the discriminator
    of siNumber: numberVal: float # 0.0 by default
    of siList: listVal: seq[char] # empty by default

# Implements echo/repr for our StackItem
proc `$`(si: StackItem): string =
  case si.kind:
  of siNumber:
    result = &"StackItem(siNumber, numberVal: {si.numberVal})"
  of siList:
    result = "StackItem(siList, listVal: @[" & si.listVal.join(", ") & "])"

# Define what it means to be true for a StackItem of kind: siNumber
converter toBool(x: StackItem): bool = 
  case x.kind:
  of siNumber: return abs(x.numberVal) < epsilon
  of siList: raise newException(CatchableError, "siList has no truth value.")

# Initialize empty stack
# element [len(stack)] refers to the TOP of the stack
var stack = initDeque[StackItem]()

#var commandStream = "4 2-" # TODO: Initialize this from register a
let command = "423.15(3.14)C2.718+c??~~c~"
var commandStream = newStringStream(command)
var operationMode: int = 0
var register: array['a'..'z', StackItem] # yep crazy shit like that is part of nim-lang

#############
# Main loop #
#############
while (var ch = readChar(commandStream); ch) != '\0':
  echo command
  echo spaces(commandStream.getPosition()-1) & "\e[1;34m^\e[00m"
  case operationMode:
  # Decimal Place Construction Mode
  # REMARK: Fully implemented
  of low(int)..(-2):
    case ch:
    of '0'..'9':
      var top = stack.popLast()

      top.numberVal += parseFloat($ch) * pow(10, float(operationMode+1))
      stack.addLast(top)
      operationMode -= 1
    of '.':
      stack.addLast(StackItem(kind: siNumber))
      operationMode = -2
    else:
      operationMode = 0
      commandStream.setPosition(getPosition(commandStream)-1)

  # Whole Number Construction Mode
  # REMARK: Fully implemented
  of -1:
    case ch:
    of '0'..'9':
      var top = stack.popLast()

      top.numberVal = top.numberVal * 10 + parseFloat($ch)
      stack.addLast(top)
    of '.':
      operationMode = -2
    else:
      operationMode = 0
      commandStream.setPosition(getPosition(commandStream)-1)


  # Execution Mode
  of 0:
    case ch:
    of '0'..'9':
      stack.addLast(StackItem(kind: siNumber, numberVal: parseFloat($ch)))
      operationMode = -1
    of '.':
      stack.addLast(StackItem(kind: siNumber))
      operationMode = -2
    of '(':
      stack.addLast(StackItem(kind: siList))
      operationMode = 1
    of 'a'..'z':
      stack.addLast(register[ch])
    of 'A'..'Z':
      register[ch.toLowerAscii()] = stack.popLast()
    of '?':
      let a = stack.popLast()
      case a.kind:
      of siList:
        if len(a.listVal) == 0: stack.addLast(StackItem(kind: siNumber, numberVal: 1.0))
        else: stack.addLast(StackItem(kind: siNumber))
      of siNumber:
        if a: stack.addLast(StackItem(kind: siNumber, numberVal: 1.0))
        else: stack.addLast(StackItem(kind: siNumber))
    of '+':
      let b = stack.popLast() # Intentionally b then a, since this is the order for - and /
      let a = stack.popLast()
      # FIXME: Check if not a number ...
      stack.addLast(StackItem(kind: siNumber, numberVal: a.numberVal + b.numberVal))
    of '~':
      case stack[^1].kind:
      of siNumber: stack[^1].numberVal *= -1.0
      of siList: stack[^1] = StackItem(kind: siList)
    else:
      discard
  
  # List Construction Mode
  # REMARK: Fully implemented
  of 1..high(int):
    case ch:
    of '(':
      var top = stack.popLast()
      top.listVal.add('(')
      stack.addLast(top)
      operationMode += 1
    of ')':
      if operationMode > 1:
        var top = stack.popLast()
        top.listVal.add(')')
        stack.addLast(top)
      operationMode -= 1
    else:
      var top = stack.popLast()
      top.listVal.add(ch)
      stack.addLast(top)

  # Debug stuff
  echo "Stack:"
  for i in countdown(len(stack)-1, 0):
    echo "  ", stack[i]

  echo "\nRegisters:"
  for i in low(register)..high(register):
    if register[i] != nil: echo "  ", i, ": ", register[i]

  echo "=".repeat(0x40)
