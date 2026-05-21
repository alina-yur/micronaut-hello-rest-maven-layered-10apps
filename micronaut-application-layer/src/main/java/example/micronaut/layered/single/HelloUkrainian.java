package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloUkrainian extends BaseSingleLanguageApplication {

    private static final String GREETING = "Привіт";

    public static void main(String[] args) {
        launch(HelloUkrainian.class, args);
    }

    @Get(uri = "/hello/ukrainian", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

