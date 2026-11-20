using Microsoft.EntityFrameworkCore;

namespace {{namespace}};

public class {{name}} : DbContext
{
    public {{name}}(DbContextOptions<{{name}}> options) : base(options)
    {
    }

    {{cursor}}
}
