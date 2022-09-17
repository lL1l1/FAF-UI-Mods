local Quad = import("Quad.lua").Quad

function Test()
    local q = Quad(
        Vector(1, 0, 4),
        Vector(5, 0, 5),
        Vector(4, 0, 2),
        Vector(2, 0, 1)
    )
    assert(q:Contains(Vector(2, 0, 3)))
    assert(q:Contains(Vector(2, 0, 2)))
    assert(q:Contains(Vector(3, 0, 3)))
    assert(not q:Contains(Vector(-2, 0, 3)))
    assert(not q:Contains(Vector(6, 0, 6)))
    assert(not q:Contains(Vector(3, 0, 6)))
    assert(not q:Contains(Vector(6, 0, 3)))
end

function Main(isReplay)
    ForkThread(Test)
end
