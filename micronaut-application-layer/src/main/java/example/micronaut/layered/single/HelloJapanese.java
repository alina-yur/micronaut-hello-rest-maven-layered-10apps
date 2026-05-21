package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloJapanese extends BaseSingleLanguageApplication {

    private static final String GREETING = "こんにちは";

    public static void main(String[] args) {
        launch(HelloJapanese.class, args);
    }

    @Get(uri = "/hello/japanese", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

