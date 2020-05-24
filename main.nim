import deques, strformat, strutils

type
  StackItemKind = enum
    siNumber,        
    siList,      
  StackItem = ref object
    case kind: StackItemKind # the ``kind`` field is the discriminator
    of siNumber: numberVal: float
    of siList: listVal: seq[float]

# Implements echo/repr for our StackItem
proc `$`(si: StackItem): string =
  case si.kind:
  of siNumber:
    result = &"StackItem(siNumber, numberVal: {si.numberVal})"
  of siList:
    result = "StackItem(siList, listVal: @[" & si.listVal.join(", ") & "])"


# Initialize empty stack
var stack = initDeque[StackItem]()

#for i in 1..5:
#  stack.addLast(StackItem(kind: siNumber, numberVal: i.toFloat))
#stack.addLast(StackItem(kind: siList, listVal: @[9.1, 9.2, 9.3]))

var commandStream = "4 2-" # TODO: Initialize this from register a
var operationMode: int = 0

#############
# Main loop #
#############
for ch in commandStream:
  case operationMode:
  # Decimal Place Construction Mode
  of low(int)..(-2):
    discard

  # Whole Number Construction Mode
  of -1:
    discard

  # Execution Mode
  of 0:
    echo repr(ch)
    case ch:
    of '0'..'9':
      discard
    else:
      discard
  
  # List Construction Mode
  of 1..high(int):
    discard
