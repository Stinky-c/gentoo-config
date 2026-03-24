# TODO

- [ ] Ensure permissions are correct
- [ ] Tweak the kernel?
- [ ] Double check audio system is functional
    - May need a systemd user-preset
- [ ] Double check kernel boot args are correct
- [ ] Maintenance Guide
- [ ] portage build env works
    - sccache
    - zram
    - lto
- [ ] Ensure hibernate support works
- [ ] Checkout lvm snapshotting
- [ ] Smart-live-rebuild?
    - <https://packages.gentoo.org/packages/app-portage/smart-live-rebuild>
- [ ] Clean up scripts
    - Check out [ideas](#ideas)
- [ ] Theme system
    - Grub
    - Dotfiles
- [ ] Figure out nullmail
    - `emerge --config mail-mta/nullmailer`
- [ ] Better integrate bat
    - man pages
    - portage output
    - Include [gentoo-syntax-bat](https://github.com/Stinky-c/gentoo-syntax-bat)
- [ ] time every time something is emerged

## Ebuilds

- [ ] batctl - battery management
    - <https://github.com/Ooooze/batctl>
    - <https://wiki.gentoo.org/wiki/Writing_go_Ebuilds>
    - <https://devmanual.gentoo.org/eclass-reference/go-module.eclass/index.html>
- [ ] Amber-lang
    - <https://docs.amber-lang.com/>
- [ ] strace-tui
    - <https://github.com/Rodrigodd/strace-tui>

## Ideas

### elog viewer

use fzf, bat. elogv does a great job, may not need to reinvent the wheel

### Eselect news reader

unread news: `/var/lib/gentoo/news/news-{repo_name}.unread`
skip news: `/var/lib/gentoo/news/news-{repo_name}.skip`
news items: `/var/db/{repo_name}/metadata/news/{item_name}/{short_name}.{lang_code}.txt`

<https://devmanual.gentoo.org/general-concepts/news/index.html>

List all items in 'news items' and pair with 'unread news'

## Checkout

showbuild - portage build log watcher
<https://github.com/gentoo-mirror/guru/tree/master/app-portage/showbuild>

carnage - portage & eix tui
<https://github.com/gentoo-mirror/guru/blob/master/app-portage/carnage/carnage-1.3b.ebuild>

kanshi - <https://wiki.archlinux.org/title/Kanshi>

zoxide - <https://github.com/ajeetdsouza/zoxide>
pointless but fun i guess

fd - <https://github.com/sharkdp/fd?tab=readme-ov-file>
find has been cursing me for a while
