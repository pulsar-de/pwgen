--[[

    PwGen

        Author:       pulsar
        License:      GNU GPLv3
        Environment:  wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode

        Description:

        - tool for random generated passwords
        - modes can be:

            1: only characters
            2: only numbers
            3: only special charcters
            4: characters + numbers
            5: characters + numbers + special characters


        Licensed under GPLv3 / for more informations read: 'docs/LICENSE'.

]]


-------------------------------------------------------------------------------------------------------------------------------------
--// IMPORTS //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// import path constants
dofile( "data/cfg/const.lua" )

--// lib path
package.path  = ";./" .. LUALIB_PATH .. "?.lua" .. ";./" .. CORE_PATH .. "?.lua"
package.cpath = ";./" .. CLIB_PATH .. "?.dll"

--// libs
local wx   = require( "wx" )
local tool = require( "tool" )

--// table lookups
local tool_GeneratePass = tool.GeneratePass

-------------------------------------------------------------------------------------------------------------------------------------
--// BASICS //-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// app vars
local app_name         = "PwGen"
local app_version      = "v0.1"
local app_copyright    = "Copyright (C) by pulsar"
local app_license      = "GNU General Public License Version 3"
local app_env          = "Environment: " .. wxlua.wxLUA_VERSION_STRING
local app_build        = "Built with: " .. wx.wxVERSION_STRING

local app_width        = 600
local app_height       = 300

--// files
local png_tbl = {

    [ 1 ] = RES_PATH .. "GPLv3_160x80.png",
    [ 2 ] = RES_PATH .. "osi_75x100.png",
    [ 3 ] = RES_PATH .. "appicon_16x16.png",
    [ 4 ] = RES_PATH .. "appicon_32x32.png",
}

--// controls
local control, di, result
local frame
local panel
local radiobox
local amount
local password
local btn_gen
local btn_clip
local clipBoard

--// functions
local id_counter
local new_id
local menu_item
local show_about_window

--// fonts
local default_font   = wx.wxFont( 8,  wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_normal_1 = wx.wxFont( 9,  wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_normal_2 = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_bold     = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )
local formular_bold  = wx.wxFont( 15, wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )
local formular_bold2 = wx.wxFont( 8,  wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )
local spinctrl_bold = wx.wxFont( 19,  wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )
-------------------------------------------------------------------------------------------------------------------------------------
--// IDS //--------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// ID generator
id_counter = wx.wxID_HIGHEST + 1
new_id = function() id_counter = id_counter + 1; return id_counter end

--// IDs
ID_mb_settings = new_id()


-------------------------------------------------------------------------------------------------------------------------------------
--// HELPER FUNCS //-----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------
--// MENUBAR & TASKBAR //------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local bmp_exit_16x16     = wx.wxArtProvider.GetBitmap( wx.wxART_QUIT,        wx.wxART_TOOLBAR )
local bmp_about_16x16    = wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_TOOLBAR )

menu_item = function( menu, id, name, status, bmp )
    local mi = wx.wxMenuItem( menu, id, name, status )
    mi:SetBitmap( bmp )
    bmp:delete()
    return mi
end

local main_menu = wx.wxMenu()
main_menu:Append( menu_item( main_menu, wx.wxID_EXIT,  "Beenden" .. "\tF4", "Programm beenden", bmp_exit_16x16 ) )

local help_menu = wx.wxMenu()
help_menu:Append( menu_item( help_menu, wx.wxID_ABOUT, "Über" .. "\tF2", "Informationen über das" .. " " .. app_name, bmp_about_16x16 ) )

local menu_bar = wx.wxMenuBar()
menu_bar:Append( main_menu, "Menü" )
menu_bar:Append( help_menu, "Hilfe" )

-------------------------------------------------------------------------------------------------------------------------------------
--// FRAME & PANEL //----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// app icons (menubar & taskbar)
local app_icons = wx.wxIconBundle()
app_icons:AddIcon( wx.wxIcon( png_tbl[ 3 ], wx.wxBITMAP_TYPE_PNG, 16, 16 ) )
app_icons:AddIcon( wx.wxIcon( png_tbl[ 4 ], wx.wxBITMAP_TYPE_PNG, 32, 32 ) )

--// frame
frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, app_name .. " " .. app_version, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ), wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN )
frame:Centre( wx.wxBOTH )
frame:SetMenuBar( menu_bar )
frame:SetIcons( app_icons )
frame:CreateStatusBar( 2 )
frame:SetStatusWidths( { ( app_width / 100*80 ), ( app_width / 100*20 ) } )
frame:SetStatusText( app_name .. " bereit.", 0 )
frame:SetStatusText( "", 1 )

--// main panel for frame
panel = wx.wxPanel( frame, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ) )
panel:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

--// radio array
local radioarray = {

    [ 1 ] = "letters",
    [ 2 ] = "numbers",
    [ 3 ] = "special charcters",
	[ 4 ] = "letters + numbers",
	[ 5 ] = "letters + numbers + special characters",
}

--// radiobox
radiobox = wx.wxRadioBox( panel, wx.wxID_ANY, "Choose type", wx.wxPoint( 5, 10 ), wx.wxSize( 215, 125 ), radioarray, 1, wx.wxSUNKEN_BORDER )
radiobox:SetSelection( 3 )

--// spinctrl
control = wx.wxStaticBox( panel, wx.wxID_ANY, "Characters: (max. 500)", wx.wxPoint( 5, 140 ), wx.wxSize( 215, 75 ) )
amount = wx.wxSpinCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 15, 160 ), wx.wxSize( 95, 44 ), wx.wxALIGN_CENTRE_HORIZONTAL )
amount:SetRange( 1, 500 )
amount:SetValue( 10 )
amount:SetFont( spinctrl_bold )

--// button generate
btn_gen = wx.wxButton( panel, wx.wxID_ANY, "Generate", wx.wxPoint( 113, 159 ), wx.wxSize( 100, 22 ) )
btn_gen:SetBackgroundColour( wx.wxColour( 0, 149, 221 ) )

--// button copy to clipboard
btn_clip = wx.wxButton( panel, wx.wxID_ANY, "Copy to clipboard", wx.wxPoint( 113, 183 ), wx.wxSize( 100, 22 ) )
btn_clip:SetBackgroundColour( wx.wxColour( 0, 149, 221 ) )
btn_clip:Disable()

--// textctrl
control  = wx.wxStaticBox( panel, wx.wxID_ANY, "Password", wx.wxPoint( 230, 10 ), wx.wxSize( 355, 205 ) )
password = wx.wxTextCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 240, 30 ), wx.wxSize( 335, 170 ), wx.wxTE_NOHIDESEL + wx.wxTE_PROCESS_ENTER + wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_LEFT )
password:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

--// button - event
btn_gen:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    password:SetValue( tool_GeneratePass( amount:GetValue(), radiobox:GetSelection() + 1 ) )
    frame:SetStatusText( "New password generated.", 0 )
    btn_clip:Enable( true )
end )

--// spinctrl - event
amount:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED,
function( event )
    frame:SetStatusText( "New password length: " .. amount:GetValue(), 0 )
end )

--// radiobox - event
radiobox:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_RADIOBOX_SELECTED,
function( event )
    local n = radiobox:GetSelection() + 1
    if n == 1 then
        password:SetValue( "" )
    elseif n == 2 then
        password:SetValue( "" )
    elseif n == 3 then
        password:SetValue( "" )
    elseif n == 4 then
        password:SetValue( "" )
    elseif n == 5 then
        password:SetValue( "" )
    end
    frame:SetStatusText( "New password type: " .. radioarray[ radiobox:GetSelection() + 1 ], 0 )
end )

--// button - event
btn_clip:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    clipBoard = wx.wxClipboard.Get()
    if clipBoard and clipBoard:Open() then
        clipBoard:SetData( wx.wxTextDataObject( password:GetValue() ) )
        clipBoard:Close()
    end
    btn_clip:Disable()
end )

-------------------------------------------------------------------------------------------------------------------------------------
--// DIALOG WINDOWS //---------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// about window
show_about_window = function()
   local di_abo = wx.wxDialog(
        wx.NULL,
        wx.wxID_ANY,
        "Über" .. " " .. app_name,
        wx.wxDefaultPosition,
        wx.wxSize( 320, 395 ),
        wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
    )
    di_abo:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di_abo:SetMinSize( wx.wxSize( 320, 395 ) )
    di_abo:SetMaxSize( wx.wxSize( 320, 395 ) )

    --// app logo
    local app_logo = wx.wxBitmap():ConvertToImage()
    app_logo:LoadFile( png_tbl[ 4 ] )

    control = wx.wxStaticBitmap( di_abo, wx.wxID_ANY, wx.wxBitmap( app_logo ), wx.wxPoint( 0, 15 ), wx.wxSize( app_logo:GetWidth(), app_logo:GetHeight() ) )
    control:Centre( wx.wxHORIZONTAL )
    app_logo:Destroy()

    --// app name / version
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_name .. " " .. app_version, wx.wxPoint( 0, 60 ) )
    control:SetFont( about_bold )
    control:Centre( wx.wxHORIZONTAL )

    --// app copyright
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_copyright, wx.wxPoint( 0, 90 ) )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// environment
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_env, wx.wxPoint( 0, 122 ) )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// build with
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_build, wx.wxPoint( 0, 137 ) )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// horizontal line
    control = wx.wxStaticLine( di_abo, wx.wxID_ANY, wx.wxPoint( 0, 168 ), wx.wxSize( 275, 1 ) )
    control:Centre( wx.wxHORIZONTAL )

    --// license
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_license, wx.wxPoint( 0, 180 ) )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// GPL logo
    local gpl_logo = wx.wxBitmap():ConvertToImage()
    gpl_logo:LoadFile( png_tbl[ 1 ] )

    control = wx.wxStaticBitmap( di_abo, wx.wxID_ANY, wx.wxBitmap( gpl_logo ), wx.wxPoint( 20, 220 ), wx.wxSize( gpl_logo:GetWidth(), gpl_logo:GetHeight() ) )
    gpl_logo:Destroy()

    --// OSI Logo
    local osi_logo = wx.wxBitmap():ConvertToImage()
    osi_logo:LoadFile( png_tbl[ 2 ] )

    control = wx.wxStaticBitmap( di_abo, wx.wxID_ANY, wx.wxBitmap( osi_logo ), wx.wxPoint( 200, 210 ), wx.wxSize( osi_logo:GetWidth(), osi_logo:GetHeight() ) )
    osi_logo:Destroy()

    --// button "Schließen"
    local about_btn_close = wx.wxButton( di_abo, wx.wxID_ANY, "Schließen", wx.wxPoint( 0, 335 ), wx.wxSize( 80, 20 ) )
    about_btn_close:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    about_btn_close:Centre( wx.wxHORIZONTAL )

    --// event - button "Schließen"
    about_btn_close:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        di_abo:Destroy()
    end )

    --// show dialog
    di_abo:ShowModal()
end

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN LOOP //--------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

main = function()
    frame:Show( true )
    frame:Connect( wx.wxEVT_CLOSE_WINDOW,
    function( event )
        di = wx.wxMessageDialog( frame, "Wirklich beenden?", "Hinweis", wx.wxYES_NO + wx.wxICON_QUESTION + wx.wxCENTRE )
        result = di:ShowModal(); di:Destroy()
        if result == wx.wxID_YES then
            if event then event:Skip() end
            if frame then frame:Destroy() end
        end
    end )
    -- events - menubar
    frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function( event )
        frame:Close( true )
    end )
    frame:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function( event )
        show_about_window()
    end )
end

main()
wx.wxGetApp():MainLoop()