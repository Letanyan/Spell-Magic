using Godot;
using System;

public partial class terrain : Node
{
    [Export]
    private Vector2 motion = new Vector2(0, 100);

    public override void _PhysicsProcess(float delta)
    {
        Print("hello");
    }
}
