---
title: The hack
---

Another day, another season.

After a long day of thinking about him, I get home and sit down at my laptop. 

Something is off. 

The screen flickers, and instead of my login page, a pop-up fills the display:

> *ACCESS DENIED!*

> *You need to solve this to use your laptop.*
 
What is this? 

I stare at it, my pulse picking up. I can’t afford this today. The assignment for my course is due tonight, and I haven’t uploaded it yet.

I see the challange, it's some code. Okay, this is really odd...

I have a PhD in cybersec, but I finished it years ago, and I worked hard to wipe all that knowledge from my brain. 

And assembly? Really? 

It can’t be...

No... 

Nevermind.  

I slip into programming mode. My fingers find every key on their own and fly across the keyboard faster than I can think. 

So, let’s see…

I try to remember everything I used to teach my students about x8086 16-bit assembly. 

I can’t find anything online about this architecture, because nobody uses it anymore. I’ll have to assemble and run the code myself.

Come on, brain.

~~~terminal
.MODEL SMALL
.DATA
    initial DB 52H, 45H, 41H, 4CH, 4CH, 59H
    result  DB 6 DUP(?)

.CODE
    MOV CX, 6
    LEA SI, initial
    LEA DI, result

CB:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP CB
~~~

I have two variables: one initialized, one with space reserved. 

Easy so far. Let’s see what comes next.

First, the value 6 goes into the ```CX``` register. A loop counter, probably, but I’m not sure yet what it’s counting. Then the address of the source variable goes into ```SI```, and the address of the result into ```DI```. Okay. Next, the first element of the source is loaded into al and stored in the result, and both ```SI``` and ```DI``` are incremented.

That looks like a simple copy from one variable to the other.

The loop ends, and nothing happens. 

No message, no sound, just the cursor blinking back at me. 

A copy, that’s all it does. Six bytes moved from one place to another.

I look at them again. ```52. 45. 41. 4C. 4C. 59.```

My eyes stop on the numbers before my mind catches up. 

I know these values. 

Every programmer does, even one who spent years trying to forget. Capital letters start at 41 in hex. That was the first thing I ever taught my students. 

I read what appears.

The room goes quiet. I read the word once, then twice.

Assembly? Really?

My hands are still on the keys, but they aren’t moving anymore. Behind me, the hallway light flickers.

Only one person I know would write this…

The screen goes black. Then three new windows open, one after the other, each with a blinking cursor and nothing else.

Three locks. Whoever built this wanted me to take my time.

The first one is all stack. No strings, no data, just numbers being added and subtracted, then pushed onto the stack. 

It would be a mess if I read it top to bottom. I know that, because I used to tell my students the same thing: *the stack remembers things backwards*. 
I follow the numbers down, one by one. I let the stack unwind in my head, and then check it.

~~~terminal
    MOV AX, 70
    SUB AX, 2         
    PUSH AX
    ADD AX, 1         
    PUSH AX
    ADD AX, 14         
    PUSH AX
    PUSH AX           
    SUB AX, 10        
    PUSH AX
    ADD AX, 4          
    PUSH AX
~~~

I read what it says. I read it again.

Six letters. I stare at them. It could mean anything.. 

A warning, a failed attempt, a word that belongs in a game. I tell myself it’s a coincidence. I almost believe it.

No. That’s not a coincidence…

Can’t be.

The second lock is smaller. Almost insulting. 

One multiplication: five times seventeen. I don’t even need to run it. Eighty-five. Fifty-five in hex. 

I used to tell my students: you don’t write to the screen. You ask DOS nicely. Two in ```AH```, the character in ```DL```, and you ring the bell with ```INT 21H```. 

~~~terminal
    MOV AL, 5
    MOV BL, 17
    MUL BL            
    MOV DL, AL
    MOV AH, 02H
    INT 21H
~~~

My mouth goes dry.

It sits there alone, a single letter. 

I stop breathing. Nobody types it that way except people who are in a hurry, or people who are trying to sound like they don’t care. *Someone* used to write it like that, in every message, at three in the morning, when he thought I was asleep.

No. This is just a puzzle. Someone is playing with me.

The third lock is the one that scares me. 

Shifts and rotations, every bit pushed left, every bit dragged around from the right. I picture the bits in a ring, with the last one jumping to the front. It’s elegant and showy, and so familiar that my chest tightens. He loved this instruction. He once spent an entire night showing me that ```ROR``` could turn a mistake into a letter, if you only looked at it from the right angle. 

~~~terminal
MOV AH, 02H
MOV DL, 21H
SHL DL, 1
INT 21H
MOV DL, 14H
ROR DL, 4
INT 21H
MOV DL, 84H
SHR DL, 1
INT 21H
MOV DL, 51H
ROL DL, 2
INT 21H
~~~

My hands move before I decide to let them.

The cursor keeps blinking. The apartment is silent.

I put the four results together and say them out loud, to the empty room.

```
52 45 41 4C 4C 59 20 4D 49 53 53 45 44 20 55 20 42 41 42 45
```

***REALLY MISSED U BABE***

Nobody has called me that in years. Nobody else ever called me that. And I remember exactly where I was the last time I heard it: him standing in a doorway, saying nothing, letting me leave.

I read the three words again and again, until they stop being code and turn back into a voice.

The laptop unlocks on its own. The login screen is back, as if nothing happened, and the deadline for my assignment is still counting down in the corner.

I don’t move. The assignment can wait. 

So… he saw me that day.

I read the words one more time. 

*Really missed u babe*

Four locks, four messages, and every one of them was meant for me. He didn’t just break into my network. He planned this. He knew which instructions I’d remember, which ones I’d pretend to have forgotten, and exactly how long I’d resist before my hands took over.

How did he know where I live? 

I told no one. 

How long has he been inside my network? Was it today, or has he been there all along?

I should be afraid. Part of me is. But part of me is smiling, and that scares me more.

And a new line appears on the screen:

*Took you long enough, babe.*



