Quad = ClassSimple
{
    __init = function(self, tl, tr, br, bl)
        self:Update(tl, tr, br, bl)
    end,

    Contains = function(self, point)

        local x0 = point.x
        local y0 = point.z
        local x1 = self.tl.x
        local y1 = self.tl.z
        local x2 = self.tr.x
        local y2 = self.tr.z
        local x3 = self.br.x
        local y3 = self.br.z
        local x4 = self.bl.x
        local y4 = self.bl.z

        local s1 = (x1 - x0) * (y2 - y1) - (x2 - x1) * (y1 - y0)
        local s2 = (x2 - x0) * (y3 - y2) - (x3 - x2) * (y2 - y0)
        local s3 = (x3 - x0) * (y4 - y3) - (x4 - x3) * (y3 - y0)
        local s4 = (x4 - x0) * (y1 - y4) - (x1 - x4) * (y4 - y0)
        return (s1 < 0 and s2 < 0 and s3 < 0 and s4 < 0)
    end,

    Update = function(self, tl, tr, br, bl)
        self.tl = tl
        self.tr = tr
        self.br = br
        self.bl = bl
    end
}


