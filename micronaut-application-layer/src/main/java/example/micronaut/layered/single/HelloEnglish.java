package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloEnglish extends BaseSingleLanguageApplication {

    private static final String GREETING = "Hello";

    public static void main(String[] args) {
        launch(HelloEnglish.class, args);
    }

    @Get(uri = "/hello/english", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

