Contributing to LuaUPnP
=======================

Contributions are most welcome, thanks for your interest! Read this carefully to make sure we're all on the same page.

## Licensing your contribution

All contributions will automatically go under the [MIT license](http://opensource.org/licenses/MIT). The single reason for this is a reduction of hassle, though it deviates from the [GPLv3](http://www.gnu.org/licenses/gpl-3.0.html) as used for LuaUPnP itself.
This decision is open for discussion but has seen little attention due to a lack of time. If you want to contribute under another license than MIT, please indicate this clearly, or create an issue on the topic to start the discussion so the default contributor license can be reevaluated.

## What to change

Here's some examples of things you might want to make a pull request for:

* New device implementations
* New features
* Bugfixes
* Efficiency improvements

If you have a more deeply-rooted problem with how the program is built or some
of the stylistic decisions made in the code, it's best to
[create an issue](https://github.com/Tieske/LuaUPnP/issues) before putting
the effort into a pull request. The same goes for new features - it might be
best to check the project's direction, existing pull requests, and currently open
and closed issues first.

## Style

* Two spaces, not tabs
* Minimize globals 

Look at existing code to get a good feel for the patterns we use.

## Using Git appropriately

1. [Fork the repository](https://github.com/Tieske/LuaUPnP/fork_select) to
your Github account.
2. Create a *topical branch* - a branch whose name is succint but explains what
you're doing, such as "klingon-translations"
3. Make your changes, committing at logical breaks.
4. Push your branch to your personal account
5. [Create a pull request](https://help.github.com/articles/using-pull-requests)
6. Watch for comments or acceptance

Please note - if you want to change multiple things that don't depend on each
other, make sure you check the master branch back out before making more
changes - that way we can take in each change seperately.
