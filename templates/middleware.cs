using Microsoft.AspNetCore.Http;

namespace {{namespace}};

public sealed class {{name}}
{
    private readonly RequestDelegate _next;

    public {{name}}(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        {{cursor}}
        await _next(context);
    }
}
