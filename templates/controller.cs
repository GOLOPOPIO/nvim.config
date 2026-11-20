using Microsoft.AspNetCore.Mvc;

namespace {{namespace}};

[ApiController]
[Route("api/[controller]")]
public class {{name}} : ControllerBase
{
    [HttpGet]
    public ActionResult Get()
    {
        {{cursor}}
        return Ok();
    }
}
