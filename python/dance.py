import math
import turtle as t

screen = t.Screen()
screen.bgcolor("black")
screen.tracer(0)
pen = t.Turtle()
pen.hideturtle()
pen.speed(0)
pen.width(3)

def line(start, end):
    pen.penup()
    pen.goto(start)
    pen.pendown()
    pen.goto(end)

def dancer(x, beat, color):
    y = -70
    swing = 20 * math.sin(beat)
    pen.color(color)
    line((x, y), (x, y + 45))
    pen.penup()
    pen.goto(x, y + 50)
    pen.pendown()
    pen.circle(10)
    for side in (-1, 1):
        line((x, y + 35), (x + side * 25, y + 35 + side * swing))
        line((x, y), (x + side * 20 + swing, y - 30))

def dance(beat=0):
    pen.clear()
    dancer(-100, beat, "cyan")
    dancer(100, beat + math.pi, "pink")
    dancer(0, beat + math.pi / 2, "lavender")
    screen.update()
    screen.ontimer(lambda: dance(beat + 0.2), 40)

dance()
screen.mainloop()
