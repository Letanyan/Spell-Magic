using Godot;
using System;

public partial class TestMan : CharacterBody3D
{
    public override void _PhysicsProcess(float delta)
   {
       Print("Hello");
   }
}
