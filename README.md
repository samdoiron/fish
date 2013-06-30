Fish
====
###A clean and pragmatic language that compiles to C

Fish is my answer to many of the problems I have with
typical I have with the two main camps of Systems
and Scripting languages. My main problem is their
seperation. 

Fish is a clean, user-friendly, statically-typed
scripting language that compiles to C (though other
languages would be quite easy).

I will give a more complete overview of the language 
once it is decieded, but at the moment these are the basics.

NOTE: Just because it is in the design does not mean it is
implemented.

    -- Comment

    x;int = 10 -- Create a variable
    y = 11     -- Type inference

    if x == 10 { -- If statement
        printf("%d\n", x) -- C interop
        print(x)          -- Function type inference
    }

    for i -> 1, 100 { -- For loop
        print(i)
    }

    while i > 1 {
        i -= 1
    }


