package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloGerman extends BaseSingleLanguageApplication {

    private static final String GREETING = "Hallo";

    public static void main(String[] args) {
        launch(HelloGerman.class, args);
    }

    @Get(uri = "/hello/german", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

