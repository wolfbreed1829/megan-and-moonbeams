import gleam/list
import gleam/result

pub type Story {
  Story(
    id: Int,
    title: String,
    theme: String,
    scripture: String,
    verse: String,
    chapters: List(Chapter),
    reflection: String,
  )
}

pub type Chapter {
  Chapter(title: String, text: String)
}

// Illustrative content. Replace with Megan's own stories and recordings.
pub fn all() -> List(Story) {
  [
    Story(
      0,
      "Grace in the ordinary",
      "GRACE",
      "Psalm 46:10 · KJV",
      "Be still, and know that I am God.",
      [
        Chapter(
          "The quiet",
          "Before the day asks anything of you, there is a quiet moment. A warm cup. Light on the kitchen wall. The breath you did not know you were holding. Sometimes grace arrives this gently.",
        ),
        Chapter(
          "The invitation",
          "Faith does not always begin with a great answer. Sometimes it begins with noticing: a kindness freely given, a door held open, the courage to begin again. God meets us in these ordinary places, too.",
        ),
        Chapter(
          "Enough for today",
          "You do not have to make this day extraordinary to be loved within it. Pause. Let the light find you where you are. Take the next small step, and trust that grace will meet you there.",
        ),
      ],
      "Where did you notice a little grace today?",
    ),
    Story(
      1,
      "In the waiting",
      "HOPE",
      "Psalm 30:5 · KJV",
      "Weeping may endure for a night, but joy cometh in the morning.",
      [
        Chapter(
          "A slower season",
          "There are seasons when the answer takes longer than we hoped. The days become a practice in patience. We water the ground, though we cannot yet see what is growing beneath it.",
        ),
        Chapter(
          "Room for hope",
          "Waiting can hold both honesty and hope. We can bring our questions to God without polishing them first. A prayer can be as small as: I am here. Help me through today.",
        ),
        Chapter(
          "The morning",
          "Morning rarely arrives all at once. First a soft edge of light, then a bird, then the world taking shape again. Let hope come quietly. There is room for it, even here.",
        ),
      ],
      "What can you place in God's hands today?",
    ),
    Story(
      2,
      "Light for the next step",
      "TRUST",
      "Psalm 119:105 · KJV",
      "Thy word is a lamp unto my feet, and a light unto my path.",
      [
        Chapter(
          "The path ahead",
          "A lamp does not show us the whole road. It gives us enough light to see where to place our feet. Perhaps that is a gentle picture of faith: enough light for this step, even when the distance stays hidden.",
        ),
        Chapter(
          "A little courage",
          "Courage can look very ordinary. Making the call. Offering forgiveness. Asking for help. We do not need to feel fearless before we move toward what is good.",
        ),
        Chapter(
          "Walk in the light",
          "Bring the next step to God. Let Scripture steady you, and let someone walk beside you. The road is not always clear, but you do not have to walk it alone.",
        ),
      ],
      "What is one small step you can take in faith?",
    ),
  ]
}

pub fn get(id: Int) -> Story {
  let assert [first, ..] = all()
  all() |> list.find(fn(story) { story.id == id }) |> result.unwrap(first)
}

pub fn chapter(story: Story, index: Int) -> Chapter {
  let assert [first, ..] = story.chapters
  story.chapters |> list.drop(index) |> list.first |> result.unwrap(first)
}
