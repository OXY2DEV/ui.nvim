# Changelog

## [1.1.0](https://github.com/OXY2DEV/ui.nvim/compare/v1.0.1...v1.1.0) (2025-05-01)


### Features

* add settings cmdline.row_offset and message.history_preference ([ba88497](https://github.com/OXY2DEV/ui.nvim/commit/ba88497d17afac5353cd363267e69063eff02530))
* **cmdline:** add row_offset setting ([a415d81](https://github.com/OXY2DEV/ui.nvim/commit/a415d81f5841e570a8aff6cec3ff049b3b210578))
* **config:** Added new config for `undo` & `redo` ([544f604](https://github.com/OXY2DEV/ui.nvim/commit/544f604861c1c8aad53f69d84bb979b5b36b66bb))
* **history:** always show history at the bottom ([cf6f768](https://github.com/OXY2DEV/ui.nvim/commit/cf6f7689904293496c29e8ab48aff57dbcd3ffcb))
* **history:** always show history at the bottom ([9bcbe55](https://github.com/OXY2DEV/ui.nvim/commit/9bcbe55c74f10cf856588bd614c8d24f3f5f43c3))
* less flickering when searching in cmdline ([ab32f61](https://github.com/OXY2DEV/ui.nvim/commit/ab32f61ed46fd5d29cf145050e5a4f6811bbbc09))
* less flickering when searching in cmdline ([8133081](https://github.com/OXY2DEV/ui.nvim/commit/81330810d6eac79e50020d71f58d6203515034ec))
* **message:** add history_preference setting ([c238f5a](https://github.com/OXY2DEV/ui.nvim/commit/c238f5a270615bd0f4adb7c1d8e776018e909125))


### Bug Fixes

* **messages:** `Showcmd` messages no longer update statuscolumn ([d005f52](https://github.com/OXY2DEV/ui.nvim/commit/d005f52878a6e66eb5b27591d562bcabae2ed521))
* **messages:** Fixed issue with the message partially not being shown ([20631c1](https://github.com/OXY2DEV/ui.nvim/commit/20631c131a387280167a086a0f3b8bf9d9d0a189))
* Reduced option set occurences ([24c88e4](https://github.com/OXY2DEV/ui.nvim/commit/24c88e46e6d9172cb8152afa1fe2296ab34056ea))

## [1.0.1](https://github.com/OXY2DEV/ui.nvim/compare/v1.0.0...v1.0.1) (2025-04-30)


### Bug Fixes

* **cmdline:** Fixed a bug with command-line sometimes not showing up ([6570fcc](https://github.com/OXY2DEV/ui.nvim/commit/6570fcc6e86bfb4ba2ebcdb2faa687f95a6da803)), closes [#9](https://github.com/OXY2DEV/ui.nvim/issues/9)
* **cmdline:** Fixed issues with cursor flickering in `:s/` ([17ed49d](https://github.com/OXY2DEV/ui.nvim/commit/17ed49d9fcc9329fe3844610647a6d7480f2e33c)), closes [#9](https://github.com/OXY2DEV/ui.nvim/issues/9)
* **config:** Fixed a bug with borders in the command-line pop-up menu ([dfe2e38](https://github.com/OXY2DEV/ui.nvim/commit/dfe2e38c642d76ac607e634774a9f0ecb4fda296))
* **config:** Made rules stricter for detecting option messages ([73b5572](https://github.com/OXY2DEV/ui.nvim/commit/73b5572efe856cfd7a889d71a4ad3943e3ffd2a6))
* **messages:** Fixed a bug with mesaages appearing twice on redraw ([952ca02](https://github.com/OXY2DEV/ui.nvim/commit/952ca027480a89a725c7bcb48abd5a234682b792)), closes [#10](https://github.com/OXY2DEV/ui.nvim/issues/10)

## 1.0.0 (2025-04-27)


### Features

* Added basic logging capabilities ([1f6fd87](https://github.com/OXY2DEV/ui.nvim/commit/1f6fd872f3a0d5b1e833c665bc395782fff398f8))
* Added basic message capabilities ([d3b19f3](https://github.com/OXY2DEV/ui.nvim/commit/d3b19f3dc0b0c8d92bced103a968c486ae6de59b))
* Added command support ([d95fde0](https://github.com/OXY2DEV/ui.nvim/commit/d95fde0c714750f2cb3bd086acaaeec6053ec03d))
* Added configuration sepcification ([744b408](https://github.com/OXY2DEV/ui.nvim/commit/744b408714707cece30bce303523607c39cbb14e))
* Added highlight groups ([62b52a4](https://github.com/OXY2DEV/ui.nvim/commit/62b52a4cd17703e1729161ef1a7116f052b4df85))
* **cmdline:** Added `showcmd` support ([8f455c2](https://github.com/OXY2DEV/ui.nvim/commit/8f455c2acedaa4f4e5122ec978a77009a282793e))
* **cmdline:** Added cmdline block support ([04a98de](https://github.com/OXY2DEV/ui.nvim/commit/04a98defbff28b9454eaf9c66f52c8fbac2c883d))
* **cmdline:** Added cursor support ([8b10750](https://github.com/OXY2DEV/ui.nvim/commit/8b10750fe1268539fcdc9c7a0b7f98d4e864c8a5))
* **cmdline:** Added more default command-line configs ([25fbfb7](https://github.com/OXY2DEV/ui.nvim/commit/25fbfb7f2e7d6689b44819cdc5621ef52944ba14))
* **cmdline:** Added prompt capabilities ([053ca7f](https://github.com/OXY2DEV/ui.nvim/commit/053ca7f3b834d3e34abc8c1f66d26319c0fed683))
* **cmdline:** Added special characters event support ([17553d0](https://github.com/OXY2DEV/ui.nvim/commit/17553d08d7827b58f1a21dc0e68254c314db7a35))
* **cmdline:** Added support for basic customization ([8b10750](https://github.com/OXY2DEV/ui.nvim/commit/8b10750fe1268539fcdc9c7a0b7f98d4e864c8a5))
* **cmdline:** Added text wrapping support for title ([83cbb09](https://github.com/OXY2DEV/ui.nvim/commit/83cbb090e90c56e1b09d1d04df6f6597385dd088))
* **cmdline:** Added title support ([8b10750](https://github.com/OXY2DEV/ui.nvim/commit/8b10750fe1268539fcdc9c7a0b7f98d4e864c8a5))
* **config:** Added custom notification for adding spelling ([c141b6d](https://github.com/OXY2DEV/ui.nvim/commit/c141b6d04ce4090745f1d8686e9ce4708beacd0a))
* **config:** Added missing highlights to the various pop-up menu item styles ([ea38ec1](https://github.com/OXY2DEV/ui.nvim/commit/ea38ec1cbd51fbc1e787c02de001c082e8a6f9b1))
* **log:** Added a log export command ([c8333dd](https://github.com/OXY2DEV/ui.nvim/commit/c8333dd81a7e5239ecba61378236a7ea2494b477))
* **mesaage:** Added ability to ignore messages ([bc8e0c6](https://github.com/OXY2DEV/ui.nvim/commit/bc8e0c65d4d8bb963413cb55b9fdb12761945c1e))
* **mesaage:** Added icon suppport for messages ([e5ff8e6](https://github.com/OXY2DEV/ui.nvim/commit/e5ff8e6c20b936947e39227629316f570741dc00))
* **message:** Added `msg_clear` support ([201a195](https://github.com/OXY2DEV/ui.nvim/commit/201a1951a2ee137f56a79f747da984ee92ec0da5))
* **message:** Added basic confirm() message support ([8b3840e](https://github.com/OXY2DEV/ui.nvim/commit/8b3840edeb6ea5113ae2f98517a73f82379b9384))
* **message:** Added basic history capabilities ([2409ff2](https://github.com/OXY2DEV/ui.nvim/commit/2409ff287b4c5ce028a512ac561b5c4af9eba3bc))
* **message:** Added confirmation mesaage customization ([5db009c](https://github.com/OXY2DEV/ui.nvim/commit/5db009c2b5ed20e3bf0c99f521f88ca1214454c1))
* **message:** Added decorations for messages ([11fc506](https://github.com/OXY2DEV/ui.nvim/commit/11fc50604beccc9b804feda0ced7899122439d67))
* **message:** Added list message support ([4060c21](https://github.com/OXY2DEV/ui.nvim/commit/4060c21e0f5f3e6282617a95c3704e34d7d84b96))
* **message:** Added more customisation for message history ([6366f03](https://github.com/OXY2DEV/ui.nvim/commit/6366f031ec96f64d790f98dfc20123f422d37b08))
* **message:** Added more window configuration options for messages ([e16600f](https://github.com/OXY2DEV/ui.nvim/commit/e16600fad6a4155ba2641259d3ff27a7b736ff20))
* **message:** Added replace message support ([1a48c46](https://github.com/OXY2DEV/ui.nvim/commit/1a48c46f6c982c6f3afadc812d295ccce03f4d6d))
* **message:** Added window resize support ([89b8f22](https://github.com/OXY2DEV/ui.nvim/commit/89b8f224394395f40bcd5ef19c34e84df84b01a2))
* **message:** Better borders for messages ([52a9ddc](https://github.com/OXY2DEV/ui.nvim/commit/52a9ddc2f11b0efdb64a067858aef1bea86e0227))
* **message:** Message time is now based on text length ([2b902a5](https://github.com/OXY2DEV/ui.nvim/commit/2b902a59a917aa0116619ac72e3f03a27bdeefd0))
* **popupmemu:** Added tooltip for completion menu ([c616aed](https://github.com/OXY2DEV/ui.nvim/commit/c616aed4d245cbbe4743fcf46be54d4818a30314))
* **popupmemu:** Added tooltip for completion menu ([3043ed6](https://github.com/OXY2DEV/ui.nvim/commit/3043ed6b1e8f006ae571141ff6b3df72fee041ed))
* **popupmenu:** Added completion menu support ([15a686e](https://github.com/OXY2DEV/ui.nvim/commit/15a686ef0b2fc5424540d462391e55337b5e6506))
* **popupmenu:** Added support for info in completion popup ([10d882d](https://github.com/OXY2DEV/ui.nvim/commit/10d882d62ca5c81bc72226ced245935eaa64964c))
* **popupmenu:** Added window configuration for popup menu ([4c2aeb8](https://github.com/OXY2DEV/ui.nvim/commit/4c2aeb8847677e318f835f710fdc7f0073c6f719))


### Bug Fixes

* `enable` is no longer ignored ([be7a9f1](https://github.com/OXY2DEV/ui.nvim/commit/be7a9f12aaad7312cbc8d036152fd62a3376ab52))
* `setup()` no longer ignores user config ([f46487c](https://github.com/OXY2DEV/ui.nvim/commit/f46487cabd073c9a0ca6ec034d9858232d62fc3f))
* Added default border value ([7786056](https://github.com/OXY2DEV/ui.nvim/commit/77860560a77fe1ad219bd91a8b396b07b4eed92d)), closes [#3](https://github.com/OXY2DEV/ui.nvim/issues/3)
* Added extmarks to arguments of confirm & list messages ([a144e1b](https://github.com/OXY2DEV/ui.nvim/commit/a144e1bcf99a7638d30a2af83c4f408f81cdeb82))
* **cmdline:** "" groups now get ignored ([14faefa](https://github.com/OXY2DEV/ui.nvim/commit/14faefadbce2eaf942fc23432b5ef9e889bbd0b3))
* **cmdline:** Added missimg implamentation for offset ([f7d64d4](https://github.com/OXY2DEV/ui.nvim/commit/f7d64d465749c94a5e2353e83ee10bcf9ff48dcd))
* **cmdline:** Confirm messages no longer break cmdline ([e886b6e](https://github.com/OXY2DEV/ui.nvim/commit/e886b6e0174bd582e85860e5220feb7995b64e2c))
* **cmdline:** Fixed a bug causing configuration to be retreived twice ([14faefa](https://github.com/OXY2DEV/ui.nvim/commit/14faefadbce2eaf942fc23432b5ef9e889bbd0b3))
* **cmdline:** Fixed a bug with cmdline not hiding after hit-enter ([dd80e7c](https://github.com/OXY2DEV/ui.nvim/commit/dd80e7caede16351ff7ab39f0de76b24775b283c))
* **cmdline:** Fixed redrawing issues with `:s/` ([059271f](https://github.com/OXY2DEV/ui.nvim/commit/059271f0a8c75d8f89dfa6ece1d90dbf2ac73132))
* Fixed a bug that causes message contents to have incorrect highlight range ([b715b0c](https://github.com/OXY2DEV/ui.nvim/commit/b715b0cdccc7ea537c496a61d9539cd581fc6735))
* Fixed a bug with not knowing which window to exit to ([09d77be](https://github.com/OXY2DEV/ui.nvim/commit/09d77beefd16ccb539e468bd42b11be914249ee9))
* Fixed a bug with start error messages not showing up ([0d37b91](https://github.com/OXY2DEV/ui.nvim/commit/0d37b919ee1249289b2b8d826281cf57e44b1ca5))
* Fixed event for `__prepare()` ([ebd56d9](https://github.com/OXY2DEV/ui.nvim/commit/ebd56d964b661bc08c1c7c86beb1ca8f73de4544))
* Hitting `<CR>` no longer breaks confirm window ([5e3eeb4](https://github.com/OXY2DEV/ui.nvim/commit/5e3eeb4f78841ef786a3dc0f9cabe26ac54b526c))
* **message:** Added support for window resize ([1c15fdf](https://github.com/OXY2DEV/ui.nvim/commit/1c15fdf6c4f3584aea5e120c5a935cd6b1088474))
* **message:** Confirm message no longer disappears on wrong keypress ([a273d50](https://github.com/OXY2DEV/ui.nvim/commit/a273d50111af7bf158d506b4af55b48ab436fc00))
* **message:** Empty lines no longer get ignored in messages ([42de5d8](https://github.com/OXY2DEV/ui.nvim/commit/42de5d89dec6f6ad471479aa30bbcfe6725ca1f7))
* **message:** Fixed a bug that caused captial keys to not hide the confirm window ([cdf3f90](https://github.com/OXY2DEV/ui.nvim/commit/cdf3f901ed69de21a2e7120e769e241d200c1b7b))
* **message:** Fixed a bug with `:messages` giving an error after Startup ([1eb8000](https://github.com/OXY2DEV/ui.nvim/commit/1eb800034cf0daf4d573dfa1c992d4a8bc300859))
* **message:** Fixed a bug with `g:__confrim_keys` being nil causimg errors ([a090169](https://github.com/OXY2DEV/ui.nvim/commit/a090169e8afed78bb8b2d600f19eb92503241cf5))
* **message:** Fixed a bug with highlight groups for content segmants with newlines ([7246576](https://github.com/OXY2DEV/ui.nvim/commit/7246576bcf6ddbc377b73d1906ef041b4c413903))
* **message:** Fixed a bug with statuscolumn being overwritten by plugins ([f5e3818](https://github.com/OXY2DEV/ui.nvim/commit/f5e3818cefefdcc9278d85b17a86ece5fc100a9e))
* **message:** Fixed issues with sign column not using `line_hl_group` ([ffc01fa](https://github.com/OXY2DEV/ui.nvim/commit/ffc01faaca84cd3fbbac5518de9f24f30f6f9062))
* **message:** Fixed messages appearing in wrong order ([6d32ff2](https://github.com/OXY2DEV/ui.nvim/commit/6d32ff2d2e5035beee62e960c2bbec0b12c1e21a))
* **message:** Fixed typo in `:messages` ([76113fd](https://github.com/OXY2DEV/ui.nvim/commit/76113fd0c7b0a5370e1cc89ca5f359dc6cebf0f3))
* **message:** List messages are detected during `__add()` and `__replace()` ([1e5b9d3](https://github.com/OXY2DEV/ui.nvim/commit/1e5b9d32e35c4723bdd01561ebc32e98db28b4e4))
* **message:** Message window now resizes when opening/closing the cmdline ([18d1f6b](https://github.com/OXY2DEV/ui.nvim/commit/18d1f6bc9bc43dfc14e312743f55872ba62b889f))
* **message:** Messages before UIEnter now get delayed ([236cad9](https://github.com/OXY2DEV/ui.nvim/commit/236cad9b76fa3bbaf797837dbed85b2f368dcfb6))
* **messages:** Detaching the UI now closes showmsg window ([dfb3b3f](https://github.com/OXY2DEV/ui.nvim/commit/dfb3b3f0081b89d4c9ad862d72795130a227dc0e))
* **message:** Seperated decorations for history & message window ([d55a204](https://github.com/OXY2DEV/ui.nvim/commit/d55a2041881cced74930e433cb9d1ef02d4d5396))
* **message:** Special message types are now properly handled when `replace_last = true` ([1b7b333](https://github.com/OXY2DEV/ui.nvim/commit/1b7b333a63e5261423ac7c510b0ced485d48f2ca))
* **message:** Wrapped lines no longer show `icon` & `tail` ([f26d15a](https://github.com/OXY2DEV/ui.nvim/commit/f26d15a15988e745996802e887585f850d91887b))
* **messagw:** Changing tabs recreates message window ([b28a534](https://github.com/OXY2DEV/ui.nvim/commit/b28a534055e7eb2ee5d7c82567715abb651c5c54))
* Modules are now set up when attaching ([42399ab](https://github.com/OXY2DEV/ui.nvim/commit/42399ab5f006c7ace83a5f82a0c6cd087f98b8e4))
* **popupmemu:** Popup menu now changes style based on mode ([20821dd](https://github.com/OXY2DEV/ui.nvim/commit/20821dd6c7ca792553a84eb456d21f02ff669362))
* **popupmenu:** Completion menu no longer becomes too long ([4d2c239](https://github.com/OXY2DEV/ui.nvim/commit/4d2c239e3ffff1a27904ae32890fe6484de68ac4))
* **popupmenu:** Fixed a bug with the commamd-line being visible when completion is triggered ([e91bfc2](https://github.com/OXY2DEV/ui.nvim/commit/e91bfc21b19bdc4a942c04474a3186cdc2b9f95e))
* **popupmenu:** Set PUM UI bounds ([88864c0](https://github.com/OXY2DEV/ui.nvim/commit/88864c05d28e0a45d84b2cd0c514669fae98db85))
* **utils:** Prioritize hl_id for processing content ([e6752cb](https://github.com/OXY2DEV/ui.nvim/commit/e6752cb523b130eec54ec3fad45bd13bd1c6184b))
* **utils:** Statuscolumn no longer ends with `%#Normal#` ([ba39def](https://github.com/OXY2DEV/ui.nvim/commit/ba39def96d413d574b9e03e730a3e768c3177a8b))
