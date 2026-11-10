import gleam/int
import gleam/list
import lustre
import lustre/attribute as a
import lustre/effect
import lustre/element.{type Element, element, text}
import lustre/element/html as h
import lustre/element/svg
import lustre/event as e
import stories

type Mode {
  Watch
  Listen
  Read
}

type Screen {
  Entry
  Library
  Story
  Reflection
}

type Sound {
  Quiet
  Waves
  LoadingSound
  SoundUnavailable
}

type Model {
  Model(
    mode: Mode,
    screen: Screen,
    selected: Int,
    chapter: Int,
    speaking: Bool,
    audio_error: Bool,
    motion: Bool,
    sound: Sound,
  )
}

type Message {
  SelectMode(Mode)
  Open(Screen)
  SelectStory(Int)
  NextStory
  SelectChapter(Int)
  ToggleNarration
  NarrationEnded
  NarrationFailed
  ToggleMotion
  ToggleSound
  SoundReady(Bool)
  SoundFailed
  KeyPressed(String)
}

@external(javascript, "./browser.mjs", "narrate")
fn narrate(content: String, ended: fn() -> Nil, failed: fn() -> Nil) -> Nil

@external(javascript, "./browser.mjs", "stopNarration")
fn stop_narration() -> Nil

@external(javascript, "./ocean_audio.mjs", "setOceanSound")
fn set_ocean_sound(
  enabled: Bool,
  complete: fn(Bool) -> Nil,
  failed: fn() -> Nil,
) -> Nil

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  #(Model(Read, Entry, 0, 0, False, False, True, Quiet), effect.none())
}

fn stop() {
  effect.from(fn(_) { stop_narration() })
}

fn update(model: Model, message: Message) {
  case message {
    SelectMode(mode) -> #(
      Model(..model, mode: mode, speaking: False, audio_error: False),
      stop(),
    )
    Open(screen) -> #(
      Model(..model, screen: screen, speaking: False, audio_error: False),
      stop(),
    )
    SelectStory(id) -> #(
      Model(
        ..model,
        selected: id,
        screen: Story,
        chapter: 0,
        speaking: False,
        audio_error: False,
      ),
      stop(),
    )
    NextStory -> #(
      Model(..model, selected: { model.selected + 1 } % 3, chapter: 0),
      effect.none(),
    )
    SelectChapter(index) -> #(
      Model(..model, chapter: index, speaking: False, audio_error: False),
      stop(),
    )
    ToggleNarration ->
      case model.speaking {
        True -> #(Model(..model, speaking: False), stop())
        False -> {
          let chapter =
            stories.chapter(stories.get(model.selected), model.chapter)
          #(
            Model(..model, speaking: True, audio_error: False),
            effect.from(fn(dispatch) {
              narrate(chapter.text, fn() { dispatch(NarrationEnded) }, fn() {
                dispatch(NarrationFailed)
              })
            }),
          )
        }
      }
    NarrationEnded -> #(Model(..model, speaking: False), effect.none())
    NarrationFailed -> #(
      Model(..model, speaking: False, audio_error: True),
      effect.none(),
    )
    ToggleMotion -> #(Model(..model, motion: !model.motion), effect.none())
    ToggleSound ->
      case model.sound {
        LoadingSound -> #(model, effect.none())
        _ -> #(
          Model(..model, sound: LoadingSound),
          effect.from(fn(dispatch) {
            set_ocean_sound(
              model.sound != Waves,
              fn(active) { dispatch(SoundReady(active)) },
              fn() { dispatch(SoundFailed) },
            )
          }),
        )
      }
    SoundReady(active) -> #(
      Model(..model, sound: case active {
        True -> Waves
        False -> Quiet
      }),
      effect.none(),
    )
    SoundFailed -> #(Model(..model, sound: SoundUnavailable), effect.none())
    KeyPressed("Escape") -> #(
      Model(..model, screen: Entry, speaking: False),
      stop(),
    )
    KeyPressed(_) -> #(model, effect.none())
  }
}

fn icon(name: String) -> Element(Message) {
  let path = case name {
    "moon" -> "M20.5 14.2A8.5 8.5 0 0 1 9.8 3.5 8.5 8.5 0 1 0 20.5 14.2Z"
    "play" -> "m9 5 11 7-11 7V5Z"
    "headphones" ->
      "M4 14v-3a8 8 0 0 1 16 0v3M4 13H3v7h4v-7H4Zm16 0h1v7h-4v-7h3Z"
    "book" ->
      "M12 5v15M12 5C9 3 5 3 2 4v15c3-1 7-1 10 1 3-2 7-2 10-1V4c-3-1-7-1-10 1Z"
    "arrow" -> "M4 12h15m-6-6 6 6-6 6"
    "up-right" -> "M6 18 18 6M6 6h12v12"
    "close" -> "m6 6 12 12M6 18 18 6"
    "pause" -> "M8 5v14M16 5v14"
    "waves" ->
      "M2 7c2-3 4-3 6 0s4 3 6 0 4-3 8 0M2 12c2-3 4-3 6 0s4 3 6 0 4-3 8 0M2 17c2-3 4-3 6 0s4 3 6 0 4-3 8 0"
    "spark" -> "m12 2 2.7 7.3L22 12l-7.3 2.7L12 22l-2.7-7.3L2 12l7.3-2.7L12 2Z"
    _ -> "M5 12h14"
  }
  svg.svg(
    [
      a.attribute("viewBox", "0 0 24 24"),
      a.attribute("fill", "none"),
      a.attribute("stroke", "currentColor"),
      a.attribute("stroke-width", "1.35"),
      a.attribute("stroke-linecap", "round"),
      a.attribute("stroke-linejoin", "round"),
      a.attribute("aria-hidden", "true"),
      a.class("icon"),
    ],
    [svg.path([a.attribute("d", path)])],
  )
}

fn label(content: String) {
  h.p([a.class("eyebrow")], [text(content)])
}

fn view(model: Model) {
  h.div(
    [
      a.class(case model.motion {
        True -> "experience"
        False -> "experience motion-paused"
      }),
      e.on_keydown(KeyPressed),
    ],
    [
      h.div([a.class("ocean-camera"), a.attribute("aria-hidden", "true")], [
        h.div([a.class("ocean")], [
          element(
            "canvas",
            [a.class("ocean-surface"), a.attribute("aria-hidden", "true")],
            [],
          ),
        ]),
        h.div([a.class("moon-glow")], []),
        h.div([a.class("sea-mist")], [h.i([], []), h.i([], [])]),
      ]),
      h.div([a.class("ocean-shade"), a.attribute("aria-hidden", "true")], []),
      h.div(
        [a.class("dust"), a.attribute("aria-hidden", "true")],
        list.index_map(list.repeat(Nil, 36), fn(_, index) {
          h.i(
            [
              a.class(case index % 7 == 0 {
                True -> "mote glow-mote"
                False -> "mote"
              }),
              a.attribute(
                "style",
                "--x:"
                  <> int.to_string(18 + index * 37 % 79)
                  <> "%;"
                  <> "--y:"
                  <> int.to_string(3 + index * 23 % 35)
                  <> "%;"
                  <> "--size:"
                  <> int.to_string(2 + index % 4)
                  <> "px;"
                  <> "--duration:"
                  <> int.to_string(9 + index % 13)
                  <> "s;"
                  <> "--delay:-"
                  <> int.to_string(index * 3 % 22)
                  <> "s;"
                  <> "--travel:"
                  <> int.to_string(35 + index * 17 % 100)
                  <> "px;",
              ),
            ],
            [],
          )
        }),
      ),
      h.div([a.class("cinema-veil"), a.attribute("aria-hidden", "true")], []),
      h.div([a.class("entry"), a.id("entry")], [
        h.header([a.class("topbar")], [
          h.a(
            [
              a.href("./"),
              a.class("wordmark"),
              a.aria_label("Megan and Moonbeams home"),
            ],
            [
              h.span([a.class("brand-mark")], [
                icon("moon"),
                h.span([], [text("✦")]),
              ]),
              h.span([], [
                text("Megan "),
                h.em([], [text("and")]),
                text(" Moonbeams"),
              ]),
            ],
          ),
          h.button([a.class("text-button explore"), e.on_click(Open(Library))], [
            text("The stories"),
            icon("up-right"),
          ]),
        ]),
        h.main([a.class("hero"), a.id("main")], [
          h.div([a.class("hero-copy")], [
            h.div([a.class("kicker")], [
              h.span([a.class("little-line")], []),
              text("A LITTLE FAITH. A LITTLE WONDER."),
            ]),
            h.h1([a.aria_label("Even here, there is light.")], [
              h.span(
                [a.class("title-line"), a.attribute("aria-hidden", "true")],
                [
                  h.span([a.class("title-word word-one")], [text("Even")]),
                  text(" "),
                  h.span([a.class("title-word word-two")], [text("here,")]),
                ],
              ),
              h.span(
                [a.class("title-line"), a.attribute("aria-hidden", "true")],
                [
                  h.span([a.class("title-word word-three")], [text("there is")]),
                  text(" "),
                  h.span([a.class("title-word word-four")], [
                    h.em([], [text("light.")]),
                  ]),
                ],
              ),
            ]),
            h.p([a.class("hero-note")], [
              text("Faith-filled stories, from Megan to you."),
            ]),
            mode_selector(model.mode),
            h.button([a.class("enter-button"), e.on_click(Open(Story))], [
              text(case model.mode {
                Read -> "Begin reading"
                Listen -> "Listen to a story"
                Watch -> "Enter the story"
              }),
              icon("arrow"),
            ]),
          ]),
          h.div([a.class("ocean-caption"), a.attribute("aria-hidden", "true")], [
            h.span([], []),
            text("BENEATH THE SAME MOON."),
          ]),
          h.blockquote([a.class("moon-verse")], [
            h.p([], [
              text("“In thy light"),
              h.br([]),
              text("shall we see light.”"),
            ]),
            h.cite([], [text("PSALM 36:9 · KJV")]),
          ]),
        ]),
        h.footer([a.class("entry-footer")], [
          h.div([a.class("featured")], [
            h.span([a.class("story-number")], [
              text("0" <> int.to_string(model.selected + 1)),
            ]),
            h.button([a.class("featured-story"), e.on_click(Open(Story))], [
              label("A GLIMPSE OF GRACE"),
              h.span(
                [a.class("featured-title"), a.attribute("aria-live", "polite")],
                [text(stories.get(model.selected).title)],
              ),
            ]),
            h.button(
              [
                a.class("round-button next-story"),
                a.aria_label("Next featured story"),
                e.on_click(NextStory),
              ],
              [icon("arrow")],
            ),
          ]),
          h.div([a.class("footer-actions")], [
            h.button(
              [a.class("stillness-button"), e.on_click(Open(Reflection))],
              [icon("spark"), text("A moment of stillness")],
            ),
            h.span(
              [a.class("footer-divider"), a.attribute("aria-hidden", "true")],
              [],
            ),
            sound_button(model.sound),
            h.button(
              [
                a.class("motion-toggle"),
                a.aria_label(case model.motion {
                  True -> "Pause atmosphere animation"
                  False -> "Resume atmosphere animation"
                }),
                a.attribute("aria-pressed", case model.motion {
                  True -> "false"
                  False -> "true"
                }),
                e.on_click(ToggleMotion),
              ],
              [
                icon(case model.motion {
                  True -> "pause"
                  False -> "play"
                }),
              ],
            ),
          ]),
        ]),
      ]),
      case model.screen {
        Entry -> element.none()
        Library -> dialog("library-dialog", "The stories", library(model))
        Story ->
          dialog(
            "story-dialog",
            stories.get(model.selected).title,
            story_view(model),
          )
        Reflection ->
          dialog(
            "reflection-dialog",
            "A moment of stillness",
            reflection(model),
          )
      },
    ],
  )
}

fn sound_button(sound: Sound) {
  h.button(
    [
      a.class(case sound {
        Waves -> "sound-toggle is-playing"
        _ -> "sound-toggle"
      }),
      a.aria_label(case sound {
        Waves -> "Turn ocean sound off"
        SoundUnavailable -> "Retry ocean sound"
        _ -> "Turn ocean sound on"
      }),
      a.attribute("aria-pressed", case sound {
        Waves -> "true"
        _ -> "false"
      }),
      a.disabled(sound == LoadingSound),
      e.on_click(ToggleSound),
    ],
    [
      h.span([a.class("sound-bars"), a.attribute("aria-hidden", "true")], [
        h.i([], []),
        h.i([], []),
        h.i([], []),
        h.i([], []),
      ]),
      h.span([a.attribute("aria-live", "polite")], [
        text(case sound {
          Waves -> "Sound on"
          Quiet -> "Sound off"
          LoadingSound -> "Starting…"
          SoundUnavailable -> "Unavailable"
        }),
      ]),
    ],
  )
}

fn mode_selector(selected: Mode) {
  h.div(
    [
      a.class("mode-selector"),
      a.attribute("role", "group"),
      a.aria_label("Choose a story mode"),
    ],
    list.map(
      [
        #(Watch, "Watch", "play"),
        #(Listen, "Listen", "headphones"),
        #(Read, "Read", "book"),
      ],
      fn(item) {
        let #(mode, name, symbol) = item
        h.button(
          [
            a.class(case selected == mode {
              True -> "mode active"
              False -> "mode"
            }),
            a.attribute("aria-pressed", case selected == mode {
              True -> "true"
              False -> "false"
            }),
            e.on_click(SelectMode(mode)),
          ],
          [icon(symbol), text(name)],
        )
      },
    ),
  )
}

fn dialog(class: String, title: String, content: List(Element(Message))) {
  element(
    "dialog",
    [
      a.class("overlay " <> class),
      a.attribute("aria-label", title),
      a.attribute("data-dialog", "true"),
    ],
    [
      h.div([a.class("dialog-top")], [
        h.span([a.class("mini-brand")], [
          icon("moon"),
          text("Megan and Moonbeams"),
        ]),
        h.button(
          [
            a.class("round-button close-button"),
            a.aria_label("Return to the ocean"),
            e.on_click(Open(Entry)),
          ],
          [icon("close")],
        ),
      ]),
      h.div([a.class("dialog-content")], content),
    ],
  )
}

fn library(model: Model) {
  [
    label("THE COLLECTION"),
    h.h2([], [text("A little light, "), h.em([], [text("for you.")])]),
    h.p([a.class("muted sample-note")], [text("Sample reflections")]),
    h.div(
      [a.class("story-list")],
      list.map(stories.all(), fn(story) {
        h.button([a.class("story-row"), e.on_click(SelectStory(story.id))], [
          h.span([a.class("row-number")], [
            text("0" <> int.to_string(story.id + 1)),
          ]),
          h.span([a.class("row-copy")], [
            label(story.theme),
            h.span([a.class("row-title")], [text(story.title)]),
          ]),
          icon("arrow"),
        ])
      }),
    ),
    mode_selector(model.mode),
  ]
}

fn story_view(model: Model) {
  let story = stories.get(model.selected)
  let chapter = stories.chapter(story, model.chapter)
  [
    label(story.theme <> " · SAMPLE REFLECTION"),
    h.h2([a.id("story-title")], [text(story.title)]),
    mode_selector(model.mode),
    case model.mode {
      Watch ->
        h.div([a.class("film-preview")], [
          h.div([a.class("film-preview-copy")], [
            icon("play"),
            h.p([], [text("Megan’s first film is on its way.")]),
            h.button([a.class("text-button"), e.on_click(SelectMode(Read))], [
              text("Read a sample"),
              icon("arrow"),
            ]),
          ]),
        ])
      Listen ->
        h.div([a.class("listen-preview")], [
          h.div(
            [
              a.class(case model.speaking {
                True -> "audio-orbit playing"
                False -> "audio-orbit"
              }),
            ],
            [icon("moon")],
          ),
          h.h3([], [text(chapter.title)]),
          h.p([a.class("muted")], [text("Sample · browser narration")]),
          h.button(
            [a.class("enter-button audio-play"), e.on_click(ToggleNarration)],
            [
              icon(case model.speaking {
                True -> "pause"
                False -> "play"
              }),
              text(case model.speaking {
                True -> "Stop listening"
                False -> "Listen to this chapter"
              }),
            ],
          ),
          h.p([a.class("audio-status"), a.attribute("role", "status")], [
            text(case model.audio_error {
              True -> "Audio is unavailable here. You can read the sample."
              False -> ""
            }),
          ]),
        ])
      Read ->
        h.article([a.class("reading"), a.attribute("aria-live", "polite")], [
          h.h3([], [text(chapter.title)]),
          h.p([], [text(chapter.text)]),
        ])
    },
    case model.mode {
      Watch -> element.none()
      _ ->
        h.nav(
          [a.class("chapters"), a.aria_label("Story chapters")],
          list.index_map(story.chapters, fn(chapter, index) {
            h.button(
              [
                a.class(case model.chapter == index {
                  True -> "chapter active"
                  False -> "chapter"
                }),
                a.attribute("aria-current", case model.chapter == index {
                  True -> "step"
                  False -> "false"
                }),
                e.on_click(SelectChapter(index)),
              ],
              [
                h.span([], [text("0" <> int.to_string(index + 1))]),
                text(chapter.title),
              ],
            )
          }),
        )
    },
    h.blockquote([a.class("scripture")], [
      h.p([], [text("“" <> story.verse <> "”")]),
      h.cite([], [text(story.scripture)]),
    ]),
    case model.mode {
      Watch -> element.none()
      _ ->
        h.div([a.class("chapter-navigation")], [
          h.span([a.class("chapter-count")], [
            text("CHAPTER 0" <> int.to_string(model.chapter + 1) <> " / 03"),
          ]),
          h.button(
            [
              a.class("enter-button next-chapter"),
              e.on_click(case model.chapter < 2 {
                True -> SelectChapter(model.chapter + 1)
                False -> Open(Reflection)
              }),
            ],
            [
              text(case model.chapter < 2 {
                True -> "Next chapter"
                False -> "A moment to reflect"
              }),
              icon("arrow"),
            ],
          ),
        ])
    },
    h.button(
      [a.class("text-button reflect-link"), e.on_click(Open(Reflection))],
      [icon("spark"), text("Stay for a moment"), icon("arrow")],
    ),
  ]
}

fn reflection(model: Model) {
  let story = stories.get(model.selected)
  [
    h.div([a.class("reflection-orbit"), a.attribute("aria-hidden", "true")], [
      icon("moon"),
    ]),
    h.div(
      [
        a.class("breath-guide"),
        a.attribute("role", "img"),
        a.aria_label("Take a slow breath. Stay as long as you like."),
      ],
      [
        h.span([a.class("breath-in"), a.attribute("aria-hidden", "true")], [
          text("Breathe in"),
        ]),
        h.span([a.class("breath-out"), a.attribute("aria-hidden", "true")], [
          text("Breathe out"),
        ]),
        h.span([a.class("breath-rest"), a.attribute("aria-hidden", "true")], [
          text("Take your time"),
        ]),
      ],
    ),
    label("A MOMENT OF STILLNESS"),
    h.h2([], [text("Be still."), h.br([]), h.em([], [text("You are held.")])]),
    h.p([a.class("reflection-prompt")], [text(story.reflection)]),
    h.blockquote([a.class("scripture")], [
      h.p([], [text("“" <> story.verse <> "”")]),
      h.cite([], [text(story.scripture)]),
    ]),
    h.button([a.class("text-button return-link"), e.on_click(Open(Entry))], [
      text("Back to the ocean"),
      icon("arrow"),
    ]),
  ]
}
