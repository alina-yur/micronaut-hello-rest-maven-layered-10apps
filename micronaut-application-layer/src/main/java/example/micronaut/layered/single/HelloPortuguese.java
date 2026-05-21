package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloPortuguese extends BaseSingleLanguageApplication {

    private static final String GREETING = "Olá";

    public static void main(String[] args) {
        launch(HelloPortuguese.class, args);
    }

    @Get(uri = "/hello/portuguese", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

