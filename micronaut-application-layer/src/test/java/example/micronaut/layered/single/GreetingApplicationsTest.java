package example.micronaut.layered.single;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class GreetingApplicationsTest {

    @ParameterizedTest
    @CsvSource(delimiter = '|', textBlock = """
        english|Hello
        french|Bonjour
        german|Hallo
        spanish|Hola
        italian|Ciao
        japanese|こんにちは
        ukrainian|Привіт
        portuguese|Olá
        korean|안녕하세요
        swiss|Grüezi
        """)
    void exposesLanguageGreetingFromEachApp(String language, String greeting) {
        assertEquals(greeting, applicationFor(language).index());
        assertEquals(greeting, helloFor(language));
    }

    private static BaseSingleLanguageApplication applicationFor(String language) {
        return switch (language) {
            case "english" -> new HelloEnglish();
            case "french" -> new HelloFrench();
            case "german" -> new HelloGerman();
            case "spanish" -> new HelloSpanish();
            case "italian" -> new HelloItalian();
            case "japanese" -> new HelloJapanese();
            case "ukrainian" -> new HelloUkrainian();
            case "portuguese" -> new HelloPortuguese();
            case "korean" -> new HelloKorean();
            case "swiss" -> new HelloSwiss();
            default -> throw new IllegalArgumentException("Unsupported language: " + language);
        };
    }

    private static String helloFor(String language) {
        return switch (language) {
            case "english" -> new HelloEnglish().hello();
            case "french" -> new HelloFrench().hello();
            case "german" -> new HelloGerman().hello();
            case "spanish" -> new HelloSpanish().hello();
            case "italian" -> new HelloItalian().hello();
            case "japanese" -> new HelloJapanese().hello();
            case "ukrainian" -> new HelloUkrainian().hello();
            case "portuguese" -> new HelloPortuguese().hello();
            case "korean" -> new HelloKorean().hello();
            case "swiss" -> new HelloSwiss().hello();
            default -> throw new IllegalArgumentException("Unsupported language: " + language);
        };
    }
}

