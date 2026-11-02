func generatedRoutes() -> [Route] {
    [
        Route("/", handler: IndexRoute.render),
        Route("/about", handler: AboutRoute.render),
        Route("/hello/:name", handler: HelloNameRoute.render),
    ]
}
