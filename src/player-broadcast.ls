@include = -> @client '/player-broadcast.js': ->
    SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'
    return if SocialCalc?OrigDoPositionCalculations
    SocialCalc.OrigDoPositionCalculations = SocialCalc.DoPositionCalculations
    SocialCalc.DoPositionCalculations = ->
        SocialCalc.OrigDoPositionCalculations!
        SocialCalc.Callbacks.broadcast? \ask.ecell
        return

    SocialCalc.Sheet::ScheduleSheetCommands = (cmd, saveundo, isRemote) ->
        SocialCalc.ScheduleSheetCommands(@, cmd, saveundo, isRemote)
    SocialCalc.OrigScheduleSheetCommands = SocialCalc.ScheduleSheetCommands
    SocialCalc.ScheduleSheetCommands = (sheet, cmdstr, saveundo, isRemote) ->
        cmdstr = cmdstr.replace /\n\n+/g, '\n'
        return unless /\S/.test cmdstr
        if cmdstr and not isRemote and cmdstr isnt \redisplay and cmdstr isnt \recalc
            SocialCalc.Callbacks.broadcast? \execute { cmdstr, saveundo }
        SocialCalc.OrigScheduleSheetCommands sheet, cmdstr, saveundo, isRemote
    SocialCalc.MoveECell = (editor, newcell) ->
        highlights = editor.context.highlights
        if editor.ecell
            return newcell if editor.ecell.coord == newcell
            SocialCalc.Callbacks.broadcast? \ecell do
                original: editor.ecell.coord
                ecell: newcell
            cell = SocialCalc.GetEditorCellElement editor, editor.ecell.row, editor.ecell.col
            delete highlights[editor.ecell.coord]
            highlights[editor.ecell.coord] = \range2 if editor.range2.hasrange and editor.ecell.row >= editor.range2.top and editor.ecell.row <= editor.range2.bottom and editor.ecell.col >= editor.range2.left and editor.ecell.col <= editor.range2.right
            editor.UpdateCellCSS cell, editor.ecell.row, editor.ecell.col
            editor.SetECellHeaders ''
            editor.cellhandles.ShowCellHandles false
        else SocialCalc.Callbacks.broadcast? \ecell ecell: newcell
        newcell = editor.context.cellskip[newcell] || newcell
        editor.ecell = SocialCalc.coordToCr newcell
        editor.ecell.coord = newcell
        cell = SocialCalc.GetEditorCellElement editor, editor.ecell.row, editor.ecell.col
        highlights[newcell] = \cursor
        for f of editor.MoveECellCallback
            editor.MoveECellCallback[f] editor
        editor.UpdateCellCSS cell, editor.ecell.row, editor.ecell.col
        editor.SetECellHeaders \selected
        for f of editor.StatusCallback
            editor.StatusCallback[f].func editor, \moveecell, newcell, editor.StatusCallback[f].params
        if editor.busy
            editor.ensureecell = true
        else
            editor.ensureecell = false
            editor.EnsureECellVisible!
        return newcell
