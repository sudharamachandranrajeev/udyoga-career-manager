# google_mlkit_text_recognition refers to the Chinese, Devanagari, Japanese
# and Korean recognisers, which ship as separate optional packages. Udyoga
# only uses the Latin recogniser, so tell R8 the others are missing on
# purpose; without this, release builds fail at minifyReleaseWithR8.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
