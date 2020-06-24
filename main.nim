import deques, strformat, strutils, streams, math

# Used for comparisons
const epsilon = 5.96e-08

type
  CommandStream = ref object
    position: int
    command: string

proc getChar(stream: CommandStream): char = 
  if stream.position < stream.command.len:
    result = stream.command[stream.position]
    inc stream.position

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
  of siNumber: result = &"StackItem(siNumber, numberVal: {si.numberVal:.9f})"
  of siList: result = "StackItem(siList, listVal: @[" & si.listVal.join(", ") & "])"

# Define what it means to be true for a StackItem of kind: siNumber
converter toBool(x: StackItem): bool = 
  case x.kind:
  of siNumber: return abs(x.numberVal) > epsilon
  of siList: quit(1)

# Initialize empty stack
# element [len(stack)] refers to the TOP of the stack
var stack = initDeque[StackItem]()

# TODO: Initialize this from register a
var command = "423.15(3.14)C2.718+c??~~c~##__&J$j|?&?|jc@/-0.681529>3.4+%''''"
# command = "(9~)(8)(4!4$1+$@)@"
var commandStream = CommandStream(command: command)
var operationMode: int = 0
var register: array['a'..'z', StackItem] # yep crazy shit like that is part of nim-lang

stack.addLast(StackItem(kind:siNumber))

const debug = true
#############
# Main loop #
#############
while (var ch = getChar(commandStream); ch) != '\0':
  if debug:
    echo commandStream.command
    echo spaces(commandStream.position-1) & "\e[1;34m^\e[00m"
  case operationMode:
  # Decimal Place Construction Mode
  # REMARK: Fully implemented
  of low(int)..(-2):
    case ch:
    of '0'..'9':
      stack[^1].numberVal += parseFloat($ch) * pow(10, float(operationMode+1))
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
      stack[^1].numberVal = stack[^1].numberVal * 10 + parseFloat($ch)
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
      #NOTE: order: a = b, a < b, a > b
      let a = stack.popLast()
      let b = stack.popLast()
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
      elif a.kind == siList and b.kind == siList:
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
      elif a.kind == siList and b.kind == siNumber and ch == '>': erg = true

      if erg:
        stack.addLast(StackItem(kind: siNumber, numberVal:1))
      else:
        stack.addLast(StackItem(kind: siNumber, numberVal:0))
    of '?':
      let a = stack.popLast()
      case a.kind:
      of siNumber:
        if a: stack.addLast(StackItem(kind: siNumber))
        else: stack.addLast(StackItem(kind: siNumber, numberVal: 1.0))
      of siList:
        if len(a.listVal) == 0: stack.addLast(StackItem(kind: siNumber, numberVal: 1.0))
        else: stack.addLast(StackItem(kind: siNumber))
    of '+', '-', '*', '/', '&', '|':
      let b = stack.popLast() # Intentionally b then a, since this is the order for - and /
      let a = stack.popLast()
      if a.kind == siNumber and b.kind == siNumber:
        case ch
        of '+':
          stack.addLast(StackItem(kind: siNumber, numberVal: a.numberVal + b.numberVal))
        of '-':
          stack.addLast(StackItem(kind: siNumber, numberVal: a.numberVal - b.numberVal))
        of '*':
          stack.addLast(StackItem(kind: siNumber, numberVal: a.numberVal * b.numberVal))
        of '/':
          # Should we compare to epsilon here? We needn't but in the spirit?
          if b.numberVal == 0: # This would be inf or nan, so according to spec => empty list
            stack.addLast(StackItem(kind: siList))
          else: 
            stack.addLast(StackItem(kind: siNumber, numberVal: a.numberVal / b.numberVal))
        of '&':
          if a and b: stack.addLast(StackItem(kind: siNumber, numberVal: 1.0)) # True
          else: stack.addLast(StackItem(kind: siNumber, numberVal: 0.0)) # False
        of '|':
          if a or b: stack.addLast(StackItem(kind: siNumber, numberVal: 1.0)) # True
          else: stack.addLast(StackItem(kind: siNumber, numberVal: 0.0)) # False
        else:
          discard
      else: # If one of them is not a number, push an empty list
        stack.addLast(StackItem(kind: siList))
    of '~':
      case stack[^1].kind:
      of siNumber: stack[^1].numberVal *= -1.0
      of siList: stack[^1] = StackItem(kind: siList)
    of '%':
      case stack[^1].kind:
      of siNumber:
        let f = stack[^1].numberVal
        let r = round(f)
        let a = r - f

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
        commandStream.command.insert(join(stack.popLast().listVal), commandStream.position)
        #commandstream.command = commandstream.command[0..commandstream.position-1] & join(stack.popLast().listVal) & commandstream.command[commandstream.position..^1]
    of '\\':
      if stack[^1].kind == siList:
        commandstream.command = commandstream.command & join(stack.popLast().listVal)
    of '#':
      stack.addLast(StackItem(kind: siNumber, numberVal: float(len(stack))))
    of '\'':
      let input = readLine(stdin)
      if input[0] == '(' and input[^1] == ')':
        var parens = 1
        for i in 1..<len(input):
          case input[i]:
          of '(': parens += 1
          of ')': parens -= 1
          else: discard
          if parens < 0:
            # error, unbalanced paranthesis
            stack.addLast(StackItem(kind: siList))
            continue
        # if the input appears to be a well-formed list, append
        stack.addLast(StackItem(kind: siList, listVal: cast[seq[char]](input[1..^2])))
      else:
        try:
          let number = parseFloat(input)
          stack.addLast(StackItem(kind: siNumber, numberVal: number))
        except:
          # not a valid float
          stack.addLast(StackItem(kind: siList))
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
  if debug: 
    echo "Stack:"
    for i in countdown(len(stack)-1, 0):
      echo "  ", stack[i]

    echo "\nRegisters:"
    for i in low(register)..high(register):
      if register[i] != nil: echo "  ", i, ": ", register[i]

    echo "=".repeat(0x40)