// Exercise demo data — instructions for all 61 exercises.
// Images are loaded from assets/exercises/ based on the exercise name mapping.

class ExerciseDemo {
  final String name;
  final String muscle;
  final List<String> steps;
  final String tip;

  const ExerciseDemo({
    required this.name,
    required this.muscle,
    required this.steps,
    required this.tip,
  });
}

const Map<String, ExerciseDemo> exerciseDemos = {
  // ── Chest ──────────────────────────────────────────────
  'Barbell Bench Press': ExerciseDemo(
    name: 'Barbell Bench Press',
    muscle: 'Chest',
    steps: [
      'Lie on bench, grip bar slightly wider than shoulders',
      'Unrack bar and lower to mid-chest',
      'Press up and slightly back to lockout',
      'Keep shoulder blades pinched and feet flat',
    ],
    tip: 'Keep a slight arch in your lower back. Never bounce the bar off your chest.',
  ),
  'Incline Dumbbell Press': ExerciseDemo(
    name: 'Incline Dumbbell Press',
    muscle: 'Upper Chest',
    steps: [
      'Set bench to 30-45 degree incline',
      'Hold dumbbells at shoulder height, palms forward',
      'Press up until arms are extended',
      'Lower with control back to shoulders',
    ],
    tip: 'The incline targets upper chest. Dont go too steep or shoulders take over.',
  ),
  'Push-Ups': ExerciseDemo(
    name: 'Push-Ups',
    muscle: 'Chest, Triceps',
    steps: [
      'Hands slightly wider than shoulders, body in straight line',
      'Lower chest to just above the floor',
      'Push back up to full arm extension',
      'Keep core tight throughout — no sagging hips',
    ],
    tip: 'Scale down by doing knee push-ups if full push-ups are too hard.',
  ),
  'Machine Chest Press': ExerciseDemo(
    name: 'Machine Chest Press',
    muscle: 'Chest',
    steps: [
      'Adjust seat so handles are at chest level',
      'Grip handles and push forward',
      'Extend arms fully without locking elbows',
      'Return slowly to starting position',
    ],
    tip: 'Great for beginners. Focus on controlled reps, not heavy weight.',
  ),
  'Cable Fly': ExerciseDemo(
    name: 'Cable Fly',
    muscle: 'Chest',
    steps: [
      'Set cables at shoulder height',
      'Stand in the center, step forward for tension',
      'Bring handles together in front of chest with slight elbow bend',
      'Control the return — feel the stretch',
    ],
    tip: 'Think hugging a tree. Squeeze your chest at the peak.',
  ),
  'Dumbbell Pullover': ExerciseDemo(
    name: 'Dumbbell Pullover',
    muscle: 'Chest, Lats',
    steps: [
      'Lie across a bench, upper back supported',
      'Hold one dumbbell with both hands above chest',
      'Lower it behind your head in an arc',
      'Pull back over your chest, squeezing lats',
    ],
    tip: 'Keep a slight bend in elbows. Dont lower too far if shoulders feel tight.',
  ),
  'Decline Bench Press': ExerciseDemo(
    name: 'Decline Bench Press',
    muscle: 'Lower Chest',
    steps: [
      'Secure feet under the pads, lie back on a decline bench',
      'Grip the bar slightly wider than shoulders',
      'Lower the bar to the lower chest with control',
      'Press up and slightly back to lockout',
    ],
    tip: 'The decline angle emphasizes the lower chest. Keep feet locked under the pads.',
  ),
  'Dumbbell Fly': ExerciseDemo(
    name: 'Dumbbell Fly',
    muscle: 'Chest',
    steps: [
      'Lie on a bench, hold dumbbells above chest with a slight elbow bend',
      'Lower arms out to the sides in a wide arc',
      'Stop when you feel a comfortable chest stretch',
      'Bring dumbbells back together, squeezing chest',
    ],
    tip: 'Imagine hugging a barrel. Keep a fixed elbow bend — no pressing.',
  ),

  // ── Shoulders ──────────────────────────────────────────
  'Overhead Shoulder Press': ExerciseDemo(
    name: 'Overhead Shoulder Press',
    muscle: 'Shoulders',
    steps: [
      'Stand or sit with dumbbells at shoulder height',
      'Press straight overhead until arms lock out',
      'Lower with control back to ears',
      'Keep core braced — avoid arching back',
    ],
    tip: 'Dont lean back excessively. If standing, squeeze glutes for stability.',
  ),
  'Lateral Raises': ExerciseDemo(
    name: 'Lateral Raises',
    muscle: 'Side Delts',
    steps: [
      'Stand with dumbbells at your sides, slight elbow bend',
      'Raise arms out to the sides until shoulder height',
      'Pause briefly at the top',
      'Lower slowly — resist gravity',
    ],
    tip: 'Use light weight with strict form. Lead with your elbows, not hands.',
  ),
  'Arnold Press': ExerciseDemo(
    name: 'Arnold Press',
    muscle: 'Shoulders (all heads)',
    steps: [
      'Start with dumbbells in front of chest, palms facing you',
      'As you press up, rotate palms to face forward',
      'At the top, arms are fully extended overhead',
      'Reverse the rotation on the way down',
    ],
    tip: 'The rotation hits all three deltoid heads. Keep it smooth.',
  ),
  'Cable Lateral Raise': ExerciseDemo(
    name: 'Cable Lateral Raise',
    muscle: 'Side Delts',
    steps: [
      'Stand beside a low cable, grip handle with far hand',
      'Raise arm out to the side until shoulder height',
      'Pause and squeeze at the top',
      'Lower slowly back down',
    ],
    tip: 'Cables give constant tension throughout the range of motion.',
  ),
  'Machine Shoulder Press': ExerciseDemo(
    name: 'Machine Shoulder Press',
    muscle: 'Shoulders',
    steps: [
      'Adjust the seat so handles are at shoulder height',
      'Grip the handles and press overhead',
      'Extend arms without locking elbows',
      'Lower with control back to shoulder height',
    ],
    tip: 'A machine press is safe for beginners. Keep your back flat against the pad.',
  ),
  'Front Raise': ExerciseDemo(
    name: 'Front Raise',
    muscle: 'Front Delts',
    steps: [
      'Stand with dumbbells in front of thighs, palms facing thighs',
      'Raise one arm forward to shoulder height',
      'Lower with control, then alternate arms',
      'Keep torso still — no swinging',
    ],
    tip: 'Use light weight. Swinging defeats the purpose of this isolation exercise.',
  ),
  'Face Pull': ExerciseDemo(
    name: 'Face Pull',
    muscle: 'Rear Delts, Rotator Cuff',
    steps: [
      'Set cable at face height with rope attachment',
      'Pull rope toward your face, elbows high',
      'Spread the rope apart as you pull back',
      'Squeeze rear delts and hold briefly',
    ],
    tip: 'Essential for shoulder health. Pull to your ears, not your chin.',
  ),
  'Rear Delt Fly': ExerciseDemo(
    name: 'Rear Delt Fly',
    muscle: 'Rear Delts',
    steps: [
      'Bend forward at hips, dumbbells hanging down',
      'Raise arms out to the sides with slight elbow bend',
      'Squeeze shoulder blades together at the top',
      'Lower slowly with control',
    ],
    tip: 'Keep your back flat. Think of spreading your wings.',
  ),

  // ── Biceps ──────────────────────────────────────────────
  'Dumbbell Bicep Curl': ExerciseDemo(
    name: 'Dumbbell Bicep Curl',
    muscle: 'Biceps',
    steps: [
      'Stand with dumbbells at sides, palms forward',
      'Curl both dumbbells up by bending elbows',
      'Squeeze at the top, then lower slowly',
      'Keep elbows pinned to your sides',
    ],
    tip: 'Dont swing your body. Control the negative (lowering) phase.',
  ),
  'Hammer Curls': ExerciseDemo(
    name: 'Hammer Curls',
    muscle: 'Biceps, Brachialis',
    steps: [
      'Hold dumbbells with palms facing each other',
      'Curl up without rotating your wrists',
      'Squeeze at the top, lower slowly',
      'Elbows stay at your sides throughout',
    ],
    tip: 'Hammer curls build the brachialis — making your arms look thicker.',
  ),
  'Preacher Curl': ExerciseDemo(
    name: 'Preacher Curl',
    muscle: 'Biceps',
    steps: [
      'Rest upper arms on the preacher pad',
      'Curl the weight up, squeezing biceps',
      'Lower slowly until arms are nearly straight',
      'Dont lock out completely at the bottom',
    ],
    tip: 'Strict form — no momentum. Great for peak contraction.',
  ),
  'Concentration Curl': ExerciseDemo(
    name: 'Concentration Curl',
    muscle: 'Biceps',
    steps: [
      'Sit on bench, elbow braced against inner thigh',
      'Curl dumbbell up toward shoulder',
      'Squeeze hard at the top for 1-2 seconds',
      'Lower slowly back down',
    ],
    tip: 'Focus on the mind-muscle connection. Slow and controlled.',
  ),
  'Incline Dumbbell Curl': ExerciseDemo(
    name: 'Incline Dumbbell Curl',
    muscle: 'Biceps (long head)',
    steps: [
      'Set bench to 45-60 degrees, sit back',
      'Let arms hang straight down with dumbbells',
      'Curl up, keeping upper arms stationary',
      'Lower slowly, feeling the stretch at the bottom',
    ],
    tip: 'The incline stretches the long head of the biceps for better growth.',
  ),
  'EZ-Bar Curl': ExerciseDemo(
    name: 'EZ-Bar Curl',
    muscle: 'Biceps',
    steps: [
      'Grip the EZ-bar at the angled sections',
      'Curl up by bending at the elbows',
      'Squeeze biceps at the top',
      'Lower with control',
    ],
    tip: 'The angled grip is easier on your wrists than a straight bar.',
  ),

  // ── Triceps ─────────────────────────────────────────────
  'Cable Tricep Pushdown': ExerciseDemo(
    name: 'Cable Tricep Pushdown',
    muscle: 'Triceps',
    steps: [
      'Stand facing a high cable with straight or rope attachment',
      'Push down until arms are fully extended',
      'Squeeze triceps at the bottom',
      'Return slowly — dont let the weight yank your arms up',
    ],
    tip: 'Keep elbows locked at your sides. Only your forearms should move.',
  ),
  'Dips': ExerciseDemo(
    name: 'Dips',
    muscle: 'Triceps, Chest',
    steps: [
      'Grip parallel bars and lift yourself up',
      'Lower body by bending elbows to about 90 degrees',
      'Push back up to full extension',
      'Lean forward slightly to target chest more',
    ],
    tip: 'Lean forward for chest, stay upright for triceps.',
  ),
  'Overhead Tricep Extension': ExerciseDemo(
    name: 'Overhead Tricep Extension',
    muscle: 'Triceps (long head)',
    steps: [
      'Hold one dumbbell with both hands overhead',
      'Lower it behind your head by bending elbows',
      'Extend arms back overhead',
      'Keep elbows pointed forward and close to ears',
    ],
    tip: 'The overhead position maximally stretches the long head.',
  ),
  'Close-Grip Bench Press': ExerciseDemo(
    name: 'Close-Grip Bench Press',
    muscle: 'Triceps, Chest',
    steps: [
      'Lie on bench, grip bar with hands shoulder-width apart',
      'Lower bar to lower chest',
      'Press up, keeping elbows close to body',
      'Lock out at the top',
    ],
    tip: 'Hands should be inside shoulder width. This is a triceps-focused press.',
  ),
  'Skullcrusher': ExerciseDemo(
    name: 'Skullcrusher',
    muscle: 'Triceps',
    steps: [
      'Lie on bench, hold EZ-bar above chest with arms extended',
      'Lower bar toward forehead by bending elbows',
      'Stop just above your forehead',
      'Extend back to starting position',
    ],
    tip: 'Dont flare elbows out. Keep them pointed at the ceiling.',
  ),
  'Rope Pushdown': ExerciseDemo(
    name: 'Rope Pushdown',
    muscle: 'Triceps',
    steps: [
      'Attach rope to high cable',
      'Push down and spread the rope apart at the bottom',
      'Squeeze triceps hard',
      'Return with control',
    ],
    tip: 'Spreading the rope at the bottom gives an extra tricep contraction.',
  ),

  // ── Back ────────────────────────────────────────────────
  'Lat Pulldown': ExerciseDemo(
    name: 'Lat Pulldown',
    muscle: 'Lats, Biceps',
    steps: [
      'Grip bar wider than shoulders, lean slightly back',
      'Pull bar down to upper chest',
      'Squeeze shoulder blades together',
      'Control the return — feel the stretch',
    ],
    tip: 'Think pulling with your elbows, not your hands.',
  ),
  'Barbell Row': ExerciseDemo(
    name: 'Barbell Row',
    muscle: 'Back, Biceps',
    steps: [
      'Hinge at hips, grip bar slightly wider than shoulders',
      'Pull bar to lower chest / upper abdomen',
      'Squeeze shoulder blades together at the top',
      'Lower with control — maintain flat back',
    ],
    tip: 'Keep your core tight and back flat throughout. No rounding.',
  ),
  'Seated Cable Row': ExerciseDemo(
    name: 'Seated Cable Row',
    muscle: 'Back',
    steps: [
      'Sit with feet on footplates, knees slightly bent',
      'Pull handle to your lower abdomen',
      'Squeeze shoulder blades together',
      'Return slowly, letting shoulders stretch forward',
    ],
    tip: 'Dont lean too far back. The movement is in the arms and shoulders.',
  ),
  'Pull-Ups': ExerciseDemo(
    name: 'Pull-Ups',
    muscle: 'Lats, Biceps',
    steps: [
      'Grip bar with palms facing away, hands shoulder-width',
      'Pull yourself up until chin clears the bar',
      'Lower with control to full arm extension',
      'Dont kip — strict form only',
    ],
    tip: 'Can not do one? Use a resistance band for assistance.',
  ),
  'T-Bar Row': ExerciseDemo(
    name: 'T-Bar Row',
    muscle: 'Back',
    steps: [
      'Straddle the bar, grip handles with both hands',
      'Pull the weight toward your chest',
      'Squeeze your back muscles at the top',
      'Lower slowly with a flat back',
    ],
    tip: 'Great for thickness. Keep your chest against the pad if using a machine.',
  ),
  'Chest-Supported Row': ExerciseDemo(
    name: 'Chest-Supported Row',
    muscle: 'Upper Back',
    steps: [
      'Lie face down on an incline bench',
      'Pull dumbbells or handles up toward your sides',
      'Squeeze shoulder blades together',
      'Lower with control',
    ],
    tip: 'Eliminates cheating — pure back isolation.',
  ),
  'Inverted Row': ExerciseDemo(
    name: 'Inverted Row',
    muscle: 'Back, Biceps',
    steps: [
      'Lie under a bar set at waist height',
      'Grip the bar and pull your chest to it',
      'Keep body in a straight line',
      'Lower slowly back down',
    ],
    tip: 'Elevate your feet to make it harder. Bend knees to make it easier.',
  ),
  'Single-Arm Dumbbell Row': ExerciseDemo(
    name: 'Single-Arm Dumbbell Row',
    muscle: 'Back, Biceps',
    steps: [
      'Place one knee and hand on a bench, back flat',
      'Hold a dumbbell in the other hand, arm hanging down',
      'Row the dumbbell up to your hip',
      'Squeeze your back at the top, then lower with control',
    ],
    tip: 'The one-arm version lets you correct imbalances and use a longer range of motion.',
  ),
  'Close-Grip Pulldown': ExerciseDemo(
    name: 'Close-Grip Pulldown',
    muscle: 'Lats, Biceps',
    steps: [
      'Grip the bar with hands shoulder-width or closer',
      'Lean back slightly and pull the bar to your upper chest',
      'Squeeze your back at the bottom',
      'Control the return until arms are extended',
    ],
    tip: 'A narrow grip shifts more work to the lats and allows a deeper stretch at the top.',
  ),

  // ── Quads ───────────────────────────────────────────────
  'Quads': ExerciseDemo(
    name: 'Quads',
    muscle: 'Quads, Glutes',
    steps: [
      'Bar on upper traps, feet shoulder-width apart',
      'Brace core, push hips back and down',
      'Descend until thighs are at least parallel',
      'Drive through heels to stand back up',
    ],
    tip: 'Dont let knees cave inward. Push them out over your toes.',
  ),
  'Back Squat': ExerciseDemo(
    name: 'Back Squat',
    muscle: 'Quads, Glutes',
    steps: [
      'Bar on upper traps, feet shoulder-width apart',
      'Brace core, push hips back and down',
      'Descend until thighs are at least parallel',
      'Drive through heels to stand back up',
    ],
    tip: 'Dont let knees cave inward. Push them out over your toes.',
  ),
  'Front Squat': ExerciseDemo(
    name: 'Front Squat',
    muscle: 'Quads, Glutes',
    steps: [
      'Bar on upper traps, feet shoulder-width apart',
      'Brace core, push hips back and down',
      'Descend until thighs are at least parallel',
      'Drive through heels to stand back up',
    ],
    tip: 'Dont let knees cave inward. Push them out over your toes.',
  ),
  'Barbell Squat': ExerciseDemo(
    name: 'Barbell Squat',
    muscle: 'Quads, Glutes',
    steps: [
      'Bar on upper traps, feet shoulder-width apart',
      'Brace core, push hips back and down',
      'Descend until thighs are at least parallel',
      'Drive through heels to stand back up',
    ],
    tip: 'Drive through your whole foot and push your knees out. Full-depth reps build the most muscle.',
  ),
  'Leg Press': ExerciseDemo(
    name: 'Leg Press',
    muscle: 'Quads, Glutes',
    steps: [
      'Sit in the machine, feet shoulder-width on the platform',
      'Release the safety locks',
      'Lower the platform until knees are at 90 degrees',
      'Push back up without locking knees',
    ],
    tip: 'Dont let your lower back round off the pad at the bottom.',
  ),
  'Hack Squat': ExerciseDemo(
    name: 'Hack Squat',
    muscle: 'Quads',
    steps: [
      'Position shoulders under the pads',
      'Release safety and lower until knees are 90 degrees',
      'Push back up through your heels',
      'Keep back flat against the pad',
    ],
    tip: 'Wider stance = more glutes. Narrow stance = more quads.',
  ),
  'Walking Lunges': ExerciseDemo(
    name: 'Walking Lunges',
    muscle: 'Quads, Glutes',
    steps: [
      'Step forward into a long stride',
      'Lower back knee toward the ground',
      'Push off front foot and step forward into next lunge',
      'Alternate legs with each step',
    ],
    tip: 'Keep torso upright. Front knee should track over your toes.',
  ),
  'Leg Extension': ExerciseDemo(
    name: 'Leg Extension',
    muscle: 'Quads',
    steps: [
      'Sit in the machine, pad on lower shins',
      'Extend legs until straight',
      'Squeeze quads hard at the top',
      'Lower with control',
    ],
    tip: 'Great for finishing off quads. Use slow, controlled reps.',
  ),

  // ── Hamstrings ──────────────────────────────────────────
  'Romanian Deadlift': ExerciseDemo(
    name: 'Romanian Deadlift',
    muscle: 'Hamstrings, Glutes',
    steps: [
      'Hold bar at hip height, feet hip-width apart',
      'Push hips back, keeping legs nearly straight',
      'Lower bar along your shins until you feel a stretch',
      'Drive hips forward to return to standing',
    ],
    tip: 'The movement is in the hips, not the knees. Feel the hamstring stretch.',
  ),
  'Stiff-Leg Deadlift': ExerciseDemo(
    name: 'Stiff-Leg Deadlift',
    muscle: 'Hamstrings',
    steps: [
      'Stand with feet hip-width, bar at thighs',
      'Hinge forward with nearly straight legs',
      'Lower bar toward feet, feeling hamstring stretch',
      'Return to standing by contracting hamstrings',
    ],
    tip: 'More hamstring emphasis than RDL. Keep a slight knee bend.',
  ),
  'Single-Leg RDL': ExerciseDemo(
    name: 'Single-Leg RDL',
    muscle: 'Hamstrings, Balance',
    steps: [
      'Stand on one leg, hold dumbbell in opposite hand',
      'Hinge forward, extending free leg behind you',
      'Lower until torso is roughly parallel to floor',
      'Return to standing by contracting hamstring',
    ],
    tip: 'Great for fixing imbalances between legs. Start with light weight.',
  ),
  'Leg Curl': ExerciseDemo(
    name: 'Leg Curl',
    muscle: 'Hamstrings',
    steps: [
      'Lie face down on the machine, pad behind ankles',
      'Curl your legs up toward your glutes',
      'Squeeze hamstrings at the top',
      'Lower slowly back down',
    ],
    tip: 'Dont lift your hips off the pad. Keep the movement isolated.',
  ),
  'Stability Ball Leg Curl': ExerciseDemo(
    name: 'Stability Ball Leg Curl',
    muscle: 'Hamstrings, Core',
    steps: [
      'Lie on your back, heels on a stability ball',
      'Lift hips into a bridge position',
      'Curl the ball toward your glutes using hamstrings',
      'Extend legs back out without dropping hips',
    ],
    tip: 'Keep hips elevated throughout the entire movement.',
  ),

  // ── Glutes ──────────────────────────────────────────────
  'Hip Thrust': ExerciseDemo(
    name: 'Hip Thrust',
    muscle: 'Glutes',
    steps: [
      'Upper back on a bench, feet flat on floor',
      'Bar or weight across your hips',
      'Drive hips up until body forms a straight line',
      'Squeeze glutes hard at the top, then lower',
    ],
    tip: 'The king of glute exercises. Full range of motion is key.',
  ),
  'Glute Bridge': ExerciseDemo(
    name: 'Glute Bridge',
    muscle: 'Glutes',
    steps: [
      'Lie on your back, knees bent, feet flat on floor',
      'Push hips up toward the ceiling',
      'Squeeze glutes at the top for 2 seconds',
      'Lower slowly back down',
    ],
    tip: 'No equipment needed. Great warm-up activation exercise.',
  ),
  'Bulgarian Split Squat': ExerciseDemo(
    name: 'Bulgarian Split Squat',
    muscle: 'Quads, Glutes',
    steps: [
      'Rear foot elevated on a bench behind you',
      'Lower into a lunge until front thigh is parallel',
      'Drive through front heel to stand back up',
      'Keep torso upright throughout',
    ],
    tip: 'Brutal but effective. Start bodyweight before adding load.',
  ),
  'Cable Kickback': ExerciseDemo(
    name: 'Cable Kickback',
    muscle: 'Glutes',
    steps: [
      'Attach ankle cuff to low cable',
      'Kick leg straight back, squeezing glute',
      'Hold the contraction briefly',
      'Return leg slowly to start position',
    ],
    tip: 'Dont arch your back. The movement should come from the hip only.',
  ),

  // ── Calves ──────────────────────────────────────────────
  'Standing Calf Raises': ExerciseDemo(
    name: 'Standing Calf Raises',
    muscle: 'Calves (Gastrocnemius)',
    steps: [
      'Stand on the edge of a step, heels hanging off',
      'Rise up onto your toes as high as possible',
      'Squeeze calves at the top',
      'Lower heels below the step for a full stretch',
    ],
    tip: 'Full range of motion is critical — stretch at bottom, peak at top.',
  ),
  'Seated Calf Raises': ExerciseDemo(
    name: 'Seated Calf Raises',
    muscle: 'Calves (Soleus)',
    steps: [
      'Sit in the machine, pad on lower thighs',
      'Push up to lift the weight',
      'Hold the top position briefly',
      'Lower slowly until you feel a deep stretch',
    ],
    tip: 'The seated position targets the soleus — important for ankle stability.',
  ),
  'Single-Leg Calf Raise': ExerciseDemo(
    name: 'Single-Leg Calf Raise',
    muscle: 'Calves',
    steps: [
      'Stand on one leg on a step',
      'Rise up onto your toes',
      'Squeeze at the top for 1-2 seconds',
      'Lower slowly below the step level',
    ],
    tip: 'Hold a dumbbell for added resistance. Great for fixing imbalances.',
  ),

  // ── Core ────────────────────────────────────────────────
  'Plank': ExerciseDemo(
    name: 'Plank',
    muscle: 'Core (all)',
    steps: [
      'Forearms on the floor, body in a straight line',
      'Engage core — dont let hips sag or pike up',
      'Hold the position for the target time',
      'Breathe normally throughout',
    ],
    tip: 'Quality over time. 30 seconds of perfect form beats 2 minutes of bad form.',
  ),
  'Dead Bug': ExerciseDemo(
    name: 'Dead Bug',
    muscle: 'Core, Stability',
    steps: [
      'Lie on your back, arms extended toward ceiling',
      'Lift legs to 90 degrees, knees bent',
      'Lower opposite arm and leg toward the floor',
      'Return and repeat on the other side',
    ],
    tip: 'Press your lower back into the floor throughout. Dont rush.',
  ),
  'Mountain Climbers': ExerciseDemo(
    name: 'Mountain Climbers',
    muscle: 'Core, Cardio',
    steps: [
      'Start in a high plank, hands under shoulders',
      'Drive one knee toward your chest',
      'Quickly switch legs, alternating the sprint',
      'Keep hips low and core braced throughout',
    ],
    tip: 'Think of running in place in a plank. Keep your hips from bouncing up and down.',
  ),
  'Ab Wheel Rollout': ExerciseDemo(
    name: 'Ab Wheel Rollout',
    muscle: 'Abs, Core',
    steps: [
      'Kneel and grip the ab wheel, hands under shoulders',
      'Engage core and roll the wheel forward slowly',
      'Go only as far as you can without arching your back',
      'Pull the wheel back using your abs, not your arms',
    ],
    tip: 'Keep your spine neutral and abs braced. Stop if your lower back arches.',
  ),

  // ── Abs ─────────────────────────────────────────────────
  'Cable Crunch': ExerciseDemo(
    name: 'Cable Crunch',
    muscle: 'Abs',
    steps: [
      'Kneel facing a high cable with rope attachment',
      'Hold rope behind your head',
      'Crunch down, bringing elbows toward knees',
      'Focus on contracting abs, not pulling with arms',
    ],
    tip: 'The movement comes from curling the spine, not hinging at the hips.',
  ),
  'Bicycle Crunch': ExerciseDemo(
    name: 'Bicycle Crunch',
    muscle: 'Abs, Obliques',
    steps: [
      'Lie on your back, hands behind your head, legs lifted',
      'Bring one knee toward the opposite elbow',
      'Rotate your torso as you straighten the other leg',
      'Alternate sides in a smooth pedaling motion',
    ],
    tip: 'Keep your lower back pressed into the floor. Rotate from the ribs, not just the elbows.',
  ),
  'Hanging Leg Raise': ExerciseDemo(
    name: 'Hanging Leg Raise',
    muscle: 'Lower Abs, Hip Flexors',
    steps: [
      'Hang from a pull-up bar with straight arms',
      'Raise legs until thighs are parallel to floor',
      'Lower slowly with control',
      'Dont swing — use strict form',
    ],
    tip: 'Bend your knees to make it easier. Straight legs for more challenge.',
  ),

  // ── Obliques ────────────────────────────────────────────
  'Russian Twist': ExerciseDemo(
    name: 'Russian Twist',
    muscle: 'Obliques',
    steps: [
      'Sit with knees bent, lean torso back slightly',
      'Hold hands together or a weight at chest',
      'Rotate torso to the right, then to the left',
      'Feet can be on floor or elevated for more challenge',
    ],
    tip: 'Dont just move your arms — rotate your entire torso.',
  ),
  'Side Plank': ExerciseDemo(
    name: 'Side Plank',
    muscle: 'Obliques, Core',
    steps: [
      'Lie on your side, forearm on the ground',
      'Lift hips to form a straight line from head to feet',
      'Hold the position, keeping hips elevated',
      'Switch sides after the target time',
    ],
    tip: 'Stack your feet or place the top foot in front for more stability.',
  ),

  // ── Cardio ──────────────────────────────────────────────
  'Treadmill Incline Walk': ExerciseDemo(
    name: 'Treadmill Incline Walk',
    muscle: 'Cardio, Glutes',
    steps: [
      'Set treadmill to 10-15% incline',
      'Walk at 3.5-4.5 mph pace',
      'Pump your arms naturally',
      'Keep posture upright, dont hold the rails',
    ],
    tip: 'Incline walking burns more calories than running with less joint stress.',
  ),
  'Stationary Bike': ExerciseDemo(
    name: 'Stationary Bike',
    muscle: 'Cardio, Quads',
    steps: [
      'Adjust seat height — slight knee bend at bottom',
      'Start with 5-minute warm-up at low resistance',
      'Increase resistance for intervals or steady state',
      'Cool down with 3 minutes at easy pace',
    ],
    tip: 'Keep resistance challenging enough that you could not hold a conversation.',
  ),
  'Jump Rope': ExerciseDemo(
    name: 'Jump Rope',
    muscle: 'Cardio, Calves',
    steps: [
      'Hold handles at hip height, elbows close to body',
      'Jump just high enough for the rope to pass under',
      'Land softly on the balls of your feet',
      'Keep wrists doing the work, not big arm swings',
    ],
    tip: 'Start with 30-second intervals. It takes practice — dont give up.',
  ),
  'Rowing Machine': ExerciseDemo(
    name: 'Rowing Machine',
    muscle: 'Full Body Cardio',
    steps: [
      'Sit with feet strapped, knees slightly bent',
      'Push with legs first, then lean back slightly',
      'Pull handle to lower chest',
      'Reverse: arms extend, lean forward, bend knees',
    ],
    tip: '60% legs, 20% core, 20% arms. Drive with your legs, not your back.',
  ),
};

/// Lookup demo data for an exercise. Falls back to a generic entry.
ExerciseDemo getExerciseDemo(String exerciseName) {
  return exerciseDemos[exerciseName] ?? ExerciseDemo(
    name: exerciseName,
    muscle: 'General',
    steps: [
      'Get into the starting position',
      'Perform the movement with controlled form',
      'Complete the target reps',
      'Rest and repeat for the next set',
    ],
    tip: 'Focus on proper form and controlled breathing.',
  );
}
