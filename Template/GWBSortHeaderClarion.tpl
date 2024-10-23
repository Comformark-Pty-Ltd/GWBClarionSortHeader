#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#TEMPLATE (GWBSortHeaderClarion, 'GWB Clarion Browse Sort Header for Clarion Templates'),Family('Cw20')
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MAINTENANCE
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#EXTENSION(GWBBrowseSortHeaderClarion,'Browse Header Sort for Clarion'),DESCRIPTION('Browse Header Sort for ' & %Primary),WINDOW,REQ(BrowseBox(Clarion))
#!-------------------------------------------------------------------------------------------------------
#!-------------------------------------------------------------------------------------------------------
#SHEET,ADJUST
  #INSERT(%GWBTab1)
  #INSERT(%GWBTab2)
  #INSERT(%GWBTab3)
#ENDSHEET
#!-------------------------------------------------------------------------------------------------------
#ATSTART
  #IF(%GWBWhichColumns = 'Conditional')
    #! Create an INLIST list for specified columns
    #DECLARE(%GWBBrowseColumnsInlist)
    #SET(%GWBBrowseColumnsInlist,'')
    #FOR(%GWBSortableColumns)
      #FIX(%GWBBrowseColumns,%GWBSortableColumn)
      #IF(%GWBBrowseColumnsInlist)
        #SET(%GWBBrowseColumnsInlist,%GWBBrowseColumnsInlist & ',' &INSTANCE(%GWBBrowseColumns))
      #ELSE
        #SET(%GWBBrowseColumnsInlist,INSTANCE(%GWBBrowseColumns))
      #ENDIF
    #ENDFOR
  #ENDIF
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%DataSection),LAST
#INSERT(%GWBLocalData),NOINDENT
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%ProcedureRoutines,'',''),PRIORITY(1000)
BhsLoadQueue%ActiveTemplateInstance  ROUTINE #<! GWBBrowseSortHeaderClarion
  #IF(%GWBWhichColumns = 'All')
    #INSERT(%GWBSaveFieldnames)
  #ENDIF
  FREE(BhsQ%ActiveTemplateInstance)
  LOOP BhsCounter%ActiveTemplateInstance = 1 TO %GWBBrowseColumnCount
    #IF(%GWBWhichColumns = 'Conditional')
    IF NOT INLIST(BhsCounter%ActiveTemplateInstance,%GWBBrowseColumnsInlist)   #<! GWBBrowseSortHeaderClarion only load the conditional sort columns
      CYCLE
    END
    #ENDIF
    BhsQ%ActiveTemplateInstance:ColumnNumber = BhsCounter%ActiveTemplateInstance
    BhsQ%ActiveTemplateInstance:ColumnHeader = %ListControl{PropList:Header,BhsCounter%ActiveTemplateInstance}
    BhsQ%ActiveTemplateInstance:CurrentColumn = 0
    BhsQ%ActiveTemplateInstance:CurrentOrder = 0
    ADD(BhsQ%ActiveTemplateInstance)
  END
  DO BhsShowHeaders%ActiveTemplateInstance
  EXIT

#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%ProcedureRoutines,'',''),PRIORITY(1010)
BhsSort%ActiveTemplateInstance  ROUTINE    #<! Check alert key for column click
#!
  IF KEYCODE() = MouseLeft AND %Control{PROPLIST:MouseDownZone} = LISTZONE:Header  |
  AND NOT INLIST(%ListControl{PROPLIST:MouseDownField}, %GWBLocalVariableColumnsInlist)   #<! GWBBrowseSortHeaderClarion Skip local variables
    DO BhsShowHeaders%ActiveTemplateInstance
    ForceRefresh = True
    DO RefreshWindow
  #IF(%GWBCtrlMouseLeft)
  ELSIF KEYCODE() = CtrlMouseLeft AND %Control{PROPLIST:MouseDownZone} = LISTZONE:Header |
  AND NOT INLIST(%ListControl{PROPLIST:MouseDownField}, %GWBLocalVariableColumnsInlist)    #<! GWBBrowseSortHeaderClarion Skip local variables
    DO BhsAddSortOrder%ActiveTemplateInstance
    ForceRefresh = True
    DO RefreshWindow
  #ENDIF
  END
  EXIT
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%ProcedureRoutines,'',''),PRIORITY(1020)
BhsShowHeaders%ActiveTemplateInstance  ROUTINE   #<! GWBBrowseSortHeaderClarion
  BhsIsSorted%ActiveTemplateInstance = False
    #IF(%GWBWhichColumns = 'Conditional')
  IF INLIST(%ListControl{PROPLIST:MouseDownField},%GWBBrowseColumnsInlist)    #<! GWBBrowseSortHeaderClarion If this is one of the conditional columns
    BhsIsSorted%ActiveTemplateInstance = True
  END
    #ELSE
  BhsSortOrderString%ActiveTemplateInstance = ''
    #ENDIF
  LOOP BhsCounter%ActiveTemplateInstance = 1 TO RECORDS(BhsQ%ActiveTemplateInstance)
    GET(BhsQ%ActiveTemplateInstance,BhsCounter%ActiveTemplateInstance)
    IF ErrorCode()
      BREAK
    END
    IF BhsQ%ActiveTemplateInstance:ColumnNumber = %ListControl{PROPLIST:MouseDownField}
      IF BhsQ%ActiveTemplateInstance:CurrentColumn = 1
        BhsQ%ActiveTemplateInstance:CurrentOrder = 1 - BhsQ%ActiveTemplateInstance:CurrentOrder
      ELSE
        BhsQ%ActiveTemplateInstance:CurrentColumn = 1
        BhsQ%ActiveTemplateInstance:CurrentOrder = 0
      END
        #IF(%GWBWhichColumns = 'Conditional')  #! Sorting by selected columns - save Bhs value
      Bhs%ActiveTemplateInstance = %ListControl{PROPLIST:MouseDownField} & BhsQ%ActiveTemplateInstance:CurrentOrder  #<! GWB Set a new sort order
        #ELSE                                  #! Sorting All columns, save sorted field name
      BhsSortOrderString%ActiveTemplateInstance = CHOOSE(BhsQ%ActiveTemplateInstance:CurrentOrder = 0,'+','-') & BhsFieldNames%ActiveTemplateInstance[BhsQ%ActiveTemplateInstance:ColumnNumber]
        #ENDIF
    ELSE
      BhsQ%ActiveTemplateInstance:CurrentColumn = 0
      BhsQ%ActiveTemplateInstance:CurrentOrder = 0
    END
    PUT(BhsQ%ActiveTemplateInstance)
    IF NOT INLIST(BhsCounter%ActiveTemplateInstance, %GWBLocalVariableColumnsInlist)
      %ListControl{PropList:Header,BhsQ%ActiveTemplateInstance:ColumnNumber} = BhsQ%ActiveTemplateInstance:ColumnHeader & CHOOSE(BhsQ%ActiveTemplateInstance:CurrentColumn = 1,CHOOSE(BhsQ%ActiveTemplateInstance:CurrentOrder = 1,'%GWBDescendingCharacter','%GWBAscendingCharacter'),'%GWBSortAvailableCharacter')
    END
  END
  DISPLAY()
  EXIT
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#! Only available when CtrlMouseLeft is selected and All columns can be sorted
#!-------------------------------------------------------------------------------------------------------
#AT(%ProcedureRoutines,'',''),WHERE(%GWBCtrlMouseLeft),PRIORITY(1030)
BhsAddSortOrder%ActiveTemplateInstance  ROUTINE #<! GWBBrowseSortHeaderClarion CtrlMouseLeft was clicked
  BhsSortOrderString%ActiveTemplateInstance = ''
  SORT(BhsQ%ActiveTemplateInstance,-BhsQ%ActiveTemplateInstance:CurrentColumn)
  GET(BhsQ%ActiveTemplateInstance,1)
  BhsSortedColumnCount%ActiveTemplateInstance = BhsQ%ActiveTemplateInstance:CurrentColumn + 1
  SORT(BhsQ%ActiveTemplateInstance,+BhsQ%ActiveTemplateInstance:ColumnNumber)
  BhsQ%ActiveTemplateInstance:ColumnNumber = %ListControl{PROPLIST:MouseDownField}
  GET(BhsQ%ActiveTemplateInstance,BhsQ%ActiveTemplateInstance:ColumnNumber)
  IF ErrorCode()
    STOP('Error getting queue record')
  ELSE
    IF BhsQ%ActiveTemplateInstance:ColumnNumber = %ListControl{PROPLIST:MouseDownField}
      IF BhsQ%ActiveTemplateInstance:CurrentColumn > 0                                              #<! Already sorted by this field
        BhsQ%ActiveTemplateInstance:CurrentOrder = 1 - BhsQ%ActiveTemplateInstance:CurrentOrder     #<! Reverse the order of this field
      ELSE
        BhsQ%ActiveTemplateInstance:CurrentColumn = BhsSortedColumnCount%ActiveTemplateInstance     #<! Add it to the sort order
        BhsQ%ActiveTemplateInstance:CurrentOrder = 0
      END
    END
    PUT(BhsQ%ActiveTemplateInstance)
  END

  SORT(BhsQ%ActiveTemplateInstance,-BhsQ%ActiveTemplateInstance:CurrentColumn)
  LOOP BhsCounter%ActiveTemplateInstance = 1 TO RECORDS(BhsQ%ActiveTemplateInstance)
    GET(BhsQ%ActiveTemplateInstance,BhsCounter%ActiveTemplateInstance)
    IF ErrorCode() OR BhsQ%ActiveTemplateInstance:CurrentColumn = 0                                 #<! Not a sorted column
      BREAK
    END
    BhsSortOrderString%ActiveTemplateInstance = CHOOSE(BhsQ%ActiveTemplateInstance:CurrentOrder = 0,'+','-') |
    & BhsFieldNames%ActiveTemplateInstance[BhsQ%ActiveTemplateInstance:ColumnNumber] |
    & CHOOSE(BhsQ%ActiveTemplateInstance:CurrentColumn = BhsSortedColumnCount%ActiveTemplateInstance,'',',') |
    & BhsSortOrderString%ActiveTemplateInstance

    IF NOT INLIST(BhsCounter%ActiveTemplateInstance, %GWBLocalVariableColumnsInlist)
      %ListControl{PropList:Header,BhsQ%ActiveTemplateInstance:ColumnNumber} = BhsQ%ActiveTemplateInstance:ColumnHeader & CHOOSE(BhsQ%ActiveTemplateInstance:CurrentColumn > 0,CHOOSE(BhsQ%ActiveTemplateInstance:CurrentOrder = 1,'%GWBDescendingCharacter','%GWBAscendingCharacter'),'%GWBSortAvailableCharacter') & ' ' & BhsQ%ActiveTemplateInstance:CurrentColumn
    END
  END
  DISPLAY()
  EXIT
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%PrepareAlerts)
%ListControl{PROP:ALRT,250} = MouseLeft                     #<! GWBBrowseSortHeaderClarion
    #IF(%GWBCtrlMouseLeft)
%ListControl{PROP:ALRT,251} = CtrlMouseLeft                 #<! GWBBrowseSortHeaderClarion
    #ENDIF
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%ControlEventHandling,%ListControl,'PreAlertKey')
IF KEYCODE() = MouseLeft                                    #<! GWBBrowseSortHeaderClarion
  CYCLE
END
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%ControlOtherEventHandling,%ListControl)
  #SET(%ValueConstruct,%True)
  #FOR(%ControlEvent),WHERE(%ControlEvent = 'PreAlertKey')
    #SET(%ValueConstruct,%False)
  #ENDFOR
  #IF(%ValueConstruct)
CASE EVENT()                                                 #<! GWBBrowseSortHeaderClarion
OF Event:PreAlertKey
  IF KEYCODE() = MouseLeft
    CYCLE
  END
END
  #ENDIF
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%ControlEventHandling,%ListControl,'AlertKey')
  DO BhsSort%ActiveTemplateInstance  #<! GWBBrowseSortHeaderClarion
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%BeforeAccept,'',''),LAST
  DO BhsLoadQueue%ActiveTemplateInstance  #<! GWBBrowseSortHeaderClarion
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%BrowseAfterChange,'2','')
 ! Prevent the browse from reloading #<! GWBBrowseSortHeaderClarion
 IF BhsIsSorted%ActiveTemplateInstance
   BRW%ControlInstance::RefreshMode = RefreshOnQueue
   DO BRW%ControlInstance::RefreshPage
   DO BRW%ControlInstance::InitializeBrowse
   DO BRW%ControlInstance::PostNewSelection
   SELECT(%Control)
   LocalRequest = OriginalRequest
   LocalResponse = RequestCancelled
   DO RefreshWindow
   EXIT
 END
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#AT(%BeforeOpeningListView,'1',''),WHERE(%GWBWhichColumns = 'All')
  #INSERT(%GWBSortAnyColumn)
#ENDAT
#!-------------------------------------------------------------------------------------------------------
#!
#!-------------------------------------------------------------------------------------------------------
#GROUP(%GWBLocalData)
#!
Bhs%ActiveTemplateInstance           SHORT  #<! GWBBrowseSortHeaderClarion
BhsIsSorted%ActiveTemplateInstance   LONG   #<! GWBBrowseSortHeaderClarion
BhsCounter%ActiveTemplateInstance    LONG   #<! GWBBrowseSortHeaderClarion
BhsQ%ActiveTemplateInstance  QUEUE,PRE(BhsQ%ActiveTemplateInstance)       #<! GWBBrowseSortHeaderClarion
ColumnNumber          LONG                                      #<! Which browse column
ColumnHeader          CSTRING(50)                               #<! Header of column
CurrentColumn         BYTE                                      #<! 1 = this is the current column
CurrentOrder          BYTE                                      #<! 0 = Ascending 1 = Descending
                            END
  #IF(%GWBWhichColumns = 'All')
BhsFieldNames%ActiveTemplateInstance        CSTRING(50),DIM(%GWBBrowseColumnCount) #<! GWBBrowseSortHeaderClarion - All the field names of the columns
BhsSortedColumnCount%ActiveTemplateInstance LONG #<! GWBBrowseSortHeaderClarion - How many columns currently sorted by CtrlClick
BhsSortOrderString%ActiveTemplateInstance  CSTRING(100) #<! GWBBrowseSortHeaderClarion - String containing the Prop:Order
  #ENDIF
#!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#GROUP(%GWBSaveFieldnames)
#! Save the field names for column sorting when All columns available for sorting
#DECLARE(%GWBFieldNameCounter)
#SET(%GWBFieldNameCounter,0)
CLEAR(BhsFieldNames%ActiveTemplateInstance)
#FOR(%ControlField)
  #SET(%GWBFieldNameCounter,%GWBFieldNameCounter + 1)
BhsFieldNames%ActiveTemplateInstance[%GWBFieldNameCounter] = '%ControlField' #<! GWBBrowseSortHeaderClarion
#ENDFOR
#!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#GROUP(%GWBSortAnyColumn)
! GWBBrowseSortHeaderClarion - reset the sort order according to which column was clicked
BRW%ControlInstance::UsingAdditionalSortOrder = True
BRW%ControlInstance::View:Browse{Prop:Order} = BhsSortOrderString%ActiveTemplateInstance   #<! GWBBrowseSortHeaderClarion set in BhsShowHeaders%ActiveTemplateInstance  ROUTINE
IF BRW%ControlInstance::LocateMode = LocateOnEdit
  BRW%ControlInstance::HighlightedPosition = POSITION(%Primary)
  RESET(%Primary,BRW%ControlInstance::HighlightedPosition)
ELSE
  SET(%Primary)
END
! GWBBrowseSortHeaderClarion - reset the sort order according to which column was clicked
#!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#GROUP(%GWBTab1)   #! Copyright
#!-----------------------------------------------
  #TAB('1 Copyright')
    #IMAGE('GWBCopy.gif'),AT(,,180,60)
    #BOXED ('Copyright Notice')
      #DISPLAY()
      #DISPLAY('This template is the intellectual and')
      #DISPLAY('commercial property of G W Bomford.')
      #DISPLAY('All rights are reserved worldwide.')
      #DISPLAY()
      #DISPLAY('This template must not be copied, or ')
      #DISPLAY('supplied in any way to any other person.')
      #DISPLAY()
      #DISPLAY('The author can be contacted at ')
      #DISPLAY('templates@comformark.com.au')
      #DISPLAY()
      #DISPLAY('Copyright 2015')
      #DISPLAY()
    #ENDBOXED
  #ENDTAB
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#GROUP(%GWBTab2)   #! How to sort
#!-----------------------------------------------
  #TAB('2 How to sort')
    #PREPARE
      #DECLARE(%GWBBrowseColumns),MULTI
      #DECLARE(%GWBBrowseColumnCount)
      #FIND(%ControlInstance,%ActiveTemplateParentInstance,%Control)
      #PURGE(%GWBBrowseColumns)
      #DECLARE(%GWBLocalVariableColumnsInlist)
      #SET(%GWBLocalVariableColumnsInlist,'0,0')   #! Ensure there are always at leat two values for inlist to search
      #FOR(%ControlField)
        #ADD(%GWBBrowseColumns,%ControlField)
        #SET(%GWBBrowseColumnCount, %GWBBrowseColumnCount + 1)
        #FIND(%Field,%GWBBrowseColumns)
        #IF(%Field = '')
          #SET(%GWBLocalVariableColumnsInlist,%GWBLocalVariableColumnsInlist & ',' & %GWBBrowseColumnCount) 
        #ENDIF
      #ENDFOR
    #ENDPREPARE
    #BOXED('How to sort')
      #DISPLAY()
      #DISPLAY('Select ''All'' to add header sorting to all columns.')
      #DISPLAY()
      #DISPLAY('Select ''Conditional'' to specify Conditional')
      #DISPLAY('Sort Orders in the "Browse Actions" and then')
      #DISPLAY('select those columns for sorting, on the next tab')
      #DISPLAY()
      #DISPLAY('Conditional sorting is more flexible, you can use')
      #DISPLAY('keys and multiple orders when a column header is')
      #DISPLAY('clicked, but it is more work to set up')
      #DISPLAY()
      #PROMPT('Choose which columns to sort on',OPTION),%GWBWhichColumns,REQ,DEFAULT('All'),AT(,,,40)
      #PROMPT('All',RADIO),AT(,,,15)
      #PROMPT('Conditional',RADIO),AT(,,,10)
      #DISPLAY()
    #ENDBOXED
    #PROMPT('Ascending indicator:',@S4),%GWBAscendingCharacter,DEFAULT('+'),AT(,,20)
    #PROMPT('Descending indicator:',@S4),%GWBDescendingCharacter,DEFAULT('-'),AT(,,20)
    #PROMPT('Sort available indicator:',@S4),%GWBSortAvailableCharacter,DEFAULT('**'),AT(,,20)
    #DISPLAY()
    #ENABLE(%GWBWhichColumns = 'All'),CLEAR
      #PROMPT('Allow CtrlClick on header',CHECK),%GWBCtrlMouseLeft,DEFAULT(0),AT(10,,100)
      #DISPLAY()
      #DISPLAY('Ctrl Mouseleft allows for multi column sorting')
      #DISPLAY()
    #ENDENABLE
  #ENDTAB
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#GROUP(%GWBTab3)   #! Conditional properties
#!-----------------------------------------------
  #TAB('3 Conditional options'),WHERE(%GWBWhichColumns = 'Conditional')
        #DISPLAY()
        #DISPLAY('Variable name for conditional sorting is "Bhs' & %ActiveTemplateInstance & '"')
        #DISPLAY()
        #DISPLAY('Specify conditional sort orders in the browse "Actions"')
        #DISPLAY('using a condition such as: Bhs' & %ActiveTemplateInstance & ' = 10')
        #DISPLAY('to indicate the sort order for Column 1 ascending')
        #DISPLAY('and Bhs' & %ActiveTemplateInstance & ' = 11 for Column 1 descending.')
        #DISPLAY()
        #DISPLAY('First digit is column, second digit is sort order.')
        #DISPLAY()
        #DISPLAY('In the Browse Actions specify a Key, or Additional Sort')
        #DISPLAY('Order to match the Ascending and Descending orders')
        #DISPLAY('for that column.')
        #DISPLAY()
        #DISPLAY('NOTE: You need to specify a separate condition')
        #DISPLAY('for Ascending and Descending orders, per column.')
        #DISPLAY()
        #DISPLAY('Now, insert below the columns you want to allow')
        #DISPLAY('to be sorted by a header click, matching the columns')
        #DISPLAY('specified in the browse actions.')
        #DISPLAY()
        #BUTTON('Conditional Sort Order Columns:'),MULTI(%GWBSortableColumns,%GWBSortableColumn),INLINE
            #PROMPT('Column:',FROM(%GWBBrowseColumns)),%GWBSortableColumn,UNIQUE
        #ENDBUTTON
    #ENDTAB
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
