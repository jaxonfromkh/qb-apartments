local Translations = {
    error = {
        to_far_from_door = 'You are to far away from the Doorbell',
        nobody_home = 'There is nobody home..',
    },
    success = {
        receive_apart = 'You got a apartment',
        changed_apart = 'You moved apartments',
    },
    info = {
        at_the_door = 'Someone is at the door!',
    },
    text = {
        enter = 'Enter Apartment',
        ring_doorbell = 'Ring Doorbell',
        logout = '[H] Logout Character',
        change_outfit = '[G] Change Outfit',
        open_stash = '[H] Open Stash',
        move_here = 'Move Here',
        open_door = '[G] Open Door',
        leave = '[H] Leave Apartment',
        close_menu = '⬅ Close Menu',
        tennants = 'Tennants',
        enter_move = '[H] To Enter, [G] For More',
    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
