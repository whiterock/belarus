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


for i in 1..5:
  stack.addLast(StackItem(kind: siNumber, numberVal: i.toFloat))

stack.addLast(StackItem(kind: siList, listVal: @[9.1, 9.2, 9.3]))


#############
# Main loop #
#############
while len(stack) > 0:
  echo stack.popLast()
  # stack.addFirst(StackItem(kind: siNumber, numberVal: 8.0)) # Test infinity
