import deques, strformat, strutils, streams, math

# Used for comparisons
let epsilon = 5.96e-08

type
  CommandStream = ref object
    position: int
    command: string

proc getChar(stream: CommandStream): char = 
  result = '\0'
  if stream.position < stream.command.len:
    result = stream.command[stream.position]
    stream.position += 1

proc seqToString(str: seq[char]): string =
  result = newStringOfCap(len(str))
  for ch in str:
    result.add(ch)

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
  of siList: raise newException(CatchableError, "siList has no truth value.") #NOTE: willst wirklich f*kin exceptions einbauen?

# Initialize empty stack
# element [len(stack)] refers to the TOP of the stack
var stack = initDeque[StackItem]()

#var commandStream = "4 2-" # TODO: Initialize this from register a
var command = "423.15(3.14)C2.718+c??~~c~##__"
command = "(9~)(8)(4!4$1+$@)@"
var commandStream = CommandStream(command: command)
var operationMode: int = 0
var register: array['a'..'z', StackItem] # yep crazy shit like that is part of nim-lang

stack.addLast(StackItem(kind:siNumber))

#############
# Main loop #
#############
while (var ch = getChar(commandStream); ch) != '\0':
  echo commandStream.command
  echo spaces(commandStream.position-1) & "\e[1;34m^\e[00m"
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
      commandStream.position -= 1

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
      commandStream.position -= 1

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
    of '=', '<', '>':
      #NOTE: order: a = b, a < b a > b
      var a = stack.popLast()
      var b = stack.popLast()
      var erg: bool = false

      if a.kind == siNumber and b.kind == siNumber:
        case ch:
        of '=': #NOTE:"works as long as we dont compare zero" (should we fix this?)
          erg = (abs(a.numberVal - b.numberVal) <= epsilon * max(a.numberVal, b.numberVal))
        of '>':
          erg = (a.numberVal - b.numberVal > epsilon)
        of '<':
          erg = (a.numberVal - b.numberVal < -epsilon)
        else:
          discard

      if a.kind == siList and b.kind == siList:
        case ch:
        of '=':
          erg = ($a.listVal == $b.listVal)
        of '<':
          erg = ($a.listVal < $b.listVal)
        of '>':
          erg = ($a.listVal > $b.listVal)
        else:
          discard

      if a.kind == siNumber and b.kind == siList and ch == '<': erg = true
      if a.kind == siList and b.kind == siNumber and ch == '>': erg = true

      if erg:
        stack.addLast(StackItem(kind: siNumber, numberVal:1))
      else:
        stack.addLast(StackItem(kind: siNumber, numberVal:0))
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
    #TODO: other arithmetic operations
    of '~':
      case stack[^1].kind:
      of siNumber: stack[^1].numberVal *= -1.0
      of siList: stack[^1] = StackItem(kind: siList)
    of '%':
      case stack[^1].kind:
      of siNumber:
        var f = stack[^1].numberVal
        var r = round(f)
        var a = r - f

        if f < r:
          a = f - r

        assert(abs(a) <= 0.5)

        stack.addLast(StackItem(kind:siNumber, numberVal: a))

      of siList: stack.addLast(StackItem(kind: siList))
    of '_':
      if stack[^1].kind == siNumber and stack[^1].numberVal > 0:
        stack[^1].numberVal = sqrt(stack[^1].numberVal)
    of '!':
      if stack[^1].kind == siNumber:
        let l = stack.popLast()
        var n = int(round(l.numberVal))-1

        if n <= len(stack):
          var b = deepCopy(stack[^n])
          stack.addLast(b)
        else:
          stack.addLast(l)
    of '$':
      let l = stack.popLast()
      if l.kind == siNumber:
        var n = int(round(l.numberVal))-1

        if n <= len(stack):
          var s : seq[StackItem]
          for i in 0..n-1:
            s.add(stack.popLast())
          stack.popLast() #delete item
          for i in countdown(n-1,0):
            stack.addLast(s[i])
    of '@':
      if stack[^1].kind == siList:
        let l = stack.popLast()
        commandstream.command = commandstream.command[0..commandstream.position-1] & l.listval.seqToString() & commandstream.command[commandstream.position..^1]
    of '\\':
      if stack[^1].kind == siList:
        let l = stack.popLast()
        commandstream.command = commandstream.command & l.listval.seqToString()
    of '#':
      stack.addLast(Stackitem(kind: siNumber, numberVal: float(len(stack))))
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
