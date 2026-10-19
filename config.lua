Config = {}

-- Command to open the menu (players) or control others (admins / console).
Config.Command = 'plumbob'

-- Ace permission needed to control other players' plumbobs.
-- Example (server.cfg): add_ace group.admin plumbob.admin allow
Config.AdminAce = 'plumbob.admin'

-- Allow players to toggle their own plumbob and pick a colour from the menu.
-- false = only admins / console / server exports can change it.
Config.AllowSelfToggle = true

-- Minimum time between two changes requested by the same player (ms).
Config.Cooldown = 750

Config.DefaultColor = 'green'

-- Available colours. Every model must be streamed and listed in stream/double_plumbob.ytyp.
-- Order matters: it is the order in the menu.
Config.Colors = {
    { name = 'green',  label = 'Green',  model = `double_plumbob_green` },
    { name = 'orange', label = 'Orange', model = `double_plumbob_orange` },
    { name = 'red',    label = 'Red',    model = `double_plumbob_red` },
}

-- Position: the prop is NOT attached, it is moved above the head bone every frame
-- (attached props wobble with head animations).
Config.Bone = 31086 -- SKEL_Head
Config.Offset = vector3(0.0, 0.0, 0.45) -- metres above the head bone

-- Idle animation (slow spin + bobbing).
Config.Animation = {
    enabled = true,
    spinSpeed = 90.0,  -- degrees per second
    bobHeight = 0.04,  -- metres up and down
    bobSpeed = 1.5,    -- full cycles per second
}

Config.Locale = {
    menu_title = 'Plumbob',
    menu_show = 'Show plumbob',
    menu_hide = 'Hide plumbob',
    menu_color = 'Change colour',
    no_permission = 'You do not have permission to do that.',
    self_disabled = 'You cannot change your plumbob.',
    invalid_player = 'Invalid player ID: %s',
    invalid_action = 'Invalid action. Use: %s, hide',
    shown = 'Plumbob shown for ID %d',
    hidden = 'Plumbob hidden for ID %d',
    color_set = 'Plumbob set to %s for ID %d',
    usage = 'Usage: %s <id> [colour|hide]  (no action = toggle)',
}
