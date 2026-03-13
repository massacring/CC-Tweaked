local Images = {}
Images.__index = Images
Images.num1 = paintutils.parseImage([[
 32
  2
  2
  1
 211
]])
Images.num2 = paintutils.parseImage([[
 32
3  1
  2
 2
2111
]])
Images.num3 = paintutils.parseImage([[
 32
3  2
  1
2  1
 21
]])
Images.num4 = paintutils.parseImage([[
3  2
3  1
2211
   1
   1
]])
Images.num5 = paintutils.parseImage([[
3322
2
 211
   1
211
]])
Images.num6 = paintutils.parseImage([[
 322
3
221
2  1
 11
]])
Images.num7 = paintutils.parseImage([[
3322
   1
  1
 1
2
]])
Images.num8 = paintutils.parseImage([[
 32
3  1
 21
2  1
 11
]])
Images.num9 = paintutils.parseImage([[
 32
3  1
 211
   1
211
]])
Images.num0 = paintutils.parseImage([[
 32
3  1
2  1
2  1
 11
]])
Images.jack = paintutils.parseImage([[
332
   2
   1
2  1
 21
]])
Images.queen = paintutils.parseImage([[
 32
3  2
2  1
2 1
 1 1
]])
Images.king = paintutils.parseImage([[
3  1
3 2
22
2 1
2  1
]])
Images.ace = paintutils.parseImage([[
 32
3  1
2211
2  1
2  1
]])
Images.joker = paintutils.parseImage([[
  649
  5aa9
    a9 9
  a9aaaa95
 5aaaaaa456
654aaaa9 4
 4  9999
    2211
]])
Images.spade = paintutils.parseImage([[
  2
 231
23211
  1
 211
]])
Images.heart = paintutils.parseImage([[
 5 4
56544
55544
 544
  4
]])
Images.club = paintutils.parseImage([[
 222
23211
22111
  1
 211
]])
Images.diamond = paintutils.parseImage([[
  5
 564
56544
 544
  4
]])
Images.bust = paintutils.parseImage([[
 32222  3     2   3222   32221
3     2 3     2  3    1 3  2  1
2     2 2     2 2          2
2    2  2     2  2         2
22222   2     1   222      2
2    1  2     1      1     2
2     1  2   1        1    1
2     1  2   1  2    1     1
 21111    211    2211     211
]])
Images.win = paintutils.parseImage([[
 3   2   3221 3    2
3     2 3 2   32    2
2     2   2   2 2   2
2     1   2   2 2   1
 2   1    2   2  2  1
 2 2 1    1   2   2 1
 2 2 1    1   2   1 1
  2 1     1 1 2    11
  2 1   2111   2    1
]])
Images.draw = paintutils.parseImage([[
 3222   32222     322    3   2
3    2  3    2   3   2  3     2
2     2 2     2 2     1 2     2
2     1 2     1 2     1 2     1
2     1 2    1  2222211  2   1
2     1 22221   2     1  2 2 1
2     1 2    1  2     1  2 2 1
2    1  2     1 2     1   2 1
 2211   2     1 2     1   2 1
]])

local cardLength = 13
local cardHeight = 13

function Images:drawJoker(window, x, y)
    local oldTerm = term.redirect(window)
    local borderColor = 2
    local background = 1

    term.setCursorPos(x+1, y)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    for i=1, cardHeight, 1 do
        term.setCursorPos(x, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")

        term.setCursorPos(x+1, y+i)
        term.setBackgroundColor(background)
        term.write(string.rep(" ", cardLength))

        term.setCursorPos(x+1+cardLength, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")
    end

    term.setCursorPos(x+1, y+1+cardHeight)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    term.setBackgroundColor(borderColor)
    for i=1,cardHeight,(cardHeight-1) do
        term.setCursorPos(x+1, y+i)
        term.write(" ")
        term.setCursorPos(x+cardLength, y+i)
        term.write(" ")
    end

    paintutils.drawImage(Images.joker, x+2, y+3)
    term.redirect(oldTerm)
end

function Images:drawCard(window, x, y, num, suit)
    local oldTerm = term.redirect(window)
    local borderColor = 2
    local numBackground = 1
    local suitBackgroundPrimary
    local suitBackgroundSecondary
    local suitImg

    if suit == "spade" or suit == "club" then
        suitBackgroundPrimary = 32
        suitBackgroundSecondary = 16
    elseif suit == "heart" or suit == "diamond" then
        suitBackgroundPrimary = 8
        suitBackgroundSecondary = 4
    end

    if suit == "spade" then
        suitImg = Images.spade
    elseif suit == "heart" then
        suitImg = Images.heart
    elseif suit == "club" then
        suitImg = Images.club
    elseif suit == "diamond" then
        suitImg = Images.diamond
    end

    term.setCursorPos(x+1, y)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    for i=1, cardHeight, 1 do
        term.setCursorPos(x, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")

        for j=1, cardLength, 1 do
            term.setCursorPos(x+j, y+i)
            local diagonal_forward = j + i <= math.floor((cardLength + cardHeight) / 2)+1
            local diagonal_backward = j - i >= 1
            if (i == j) then
                term.setBackgroundColor(borderColor)
            elseif (diagonal_backward) then
                if (diagonal_forward) then
                    term.setBackgroundColor(suitBackgroundPrimary)
                else
                    term.setBackgroundColor(suitBackgroundSecondary)
                end
            else
                term.setBackgroundColor(numBackground)
            end
            term.write(" ")
        end

        term.setCursorPos(x+1+cardLength, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")
    end

    term.setCursorPos(x+1, y+1+cardHeight)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    term.setBackgroundColor(borderColor)
    for i=1,cardHeight,(cardHeight-1) do
        term.setCursorPos(x+1, y+i)
        term.write(" ")
        term.setCursorPos(x+cardLength, y+i)
        term.write(" ")
    end

    paintutils.drawImage(suitImg, x+cardLength-5, y+2)
    paintutils.drawImage(num, x+2, y+cardHeight-5)
    term.redirect(oldTerm)
end

function Images:drawFaceDown(window, x, y)
    local oldTerm = term.redirect(window)
    local borderColor = 1
    local primaryColor = 32
    local secondaryColor = 16

    term.setCursorPos(x+1, y)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    for i=1, cardHeight, 1 do
        term.setCursorPos(x, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")

        for j=1, cardLength, 1 do
            if (i + j) % 2 == 1 then
                term.setBackgroundColor(primaryColor)
            else
                term.setBackgroundColor(secondaryColor)
            end
            term.setCursorPos(x+j, y+i)
            term.write(" ")
        end

        term.setCursorPos(x+1+cardLength, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")
    end

    term.setCursorPos(x+1, y+1+cardHeight)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    term.setBackgroundColor(borderColor)
    for i=1,cardHeight,(cardHeight-1) do
        term.setCursorPos(x+1, y+i)
        term.write(" ")
        term.setCursorPos(x+cardLength, y+i)
        term.write(" ")
    end

    term.redirect(oldTerm)
end

function Images:drawBust(window, x, y)
    local oldTerm = term.redirect(window)
    local length = 34
    local height = 13
    x = x - math.floor(length/2)
    y = y - math.floor(height/2)
    for i=1,height,1 do
        if i == 1 or i == height then
            term.setBackgroundColor(2)
        elseif (i > 6) then
            term.setBackgroundColor(512)
        else
            term.setBackgroundColor(1024)
        end
        term.setCursorPos(x, y+i-1)
        term.write(string.rep(" ", length))

        term.setBackgroundColor(2)
        term.setCursorPos(x, y+i-1)
        term.write(" ")
        term.setCursorPos(x + length, y+i-1)
        term.write(" ")
    end

    paintutils.drawImage(Images.bust, x+2, y+2)

    term.redirect(oldTerm)
end

function Images:drawWin(window, x, y)
    local oldTerm = term.redirect(window)
    local length = 24
    local height = 13
    x = x - math.floor(length/2)
    y = y - math.floor(height/2)
    for i=1,height,1 do
        if i == 1 or i == height then
            term.setBackgroundColor(2)
        elseif (i > 6) then
            term.setBackgroundColor(512)
        else
            term.setBackgroundColor(1024)
        end
        term.setCursorPos(x, y+i-1)
        term.write(string.rep(" ", length))

        term.setBackgroundColor(2)
        term.setCursorPos(x, y+i-1)
        term.write(" ")
        term.setCursorPos(x + length, y+i-1)
        term.write(" ")
    end

    paintutils.drawImage(Images.win, x+2, y+2)

    term.redirect(oldTerm)
end

function Images:drawDraw(window, x, y)
    local oldTerm = term.redirect(window)
    local length = 34
    local height = 13
    x = x - math.floor(length/2)
    y = y - math.floor(height/2)
    for i=1,height,1 do
        if i == 1 or i == height then
            term.setBackgroundColor(2)
        elseif (i > 6) then
            term.setBackgroundColor(512)
        else
            term.setBackgroundColor(1024)
        end
        term.setCursorPos(x, y+i-1)
        term.write(string.rep(" ", length))

        term.setBackgroundColor(2)
        term.setCursorPos(x, y+i-1)
        term.write(" ")
        term.setCursorPos(x + length, y+i-1)
        term.write(" ")
    end

    paintutils.drawImage(Images.draw, x+2, y+2)

    term.redirect(oldTerm)
end

return Images