package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloKorean extends BaseSingleLanguageApplication {

    private static final String GREETING = "안녕하세요";

    public static void main(String[] args) {
        launch(HelloKorean.class, args);
    }

    @Get(uri = "/hello/korean", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

