struct FormPostRoute {
    static func render(_ context: PageContext) -> Reply {
        do {
            let fields = try context.request.form()
            let name = fields.first { $0.0 == "name" }?.1 ?? ""
            guard !name.isEmpty else {
                return .text("name is required\n", status: .badRequest)
            }
            let content = element("main") {
                element("h1") { "hello, \(name)!" }
                element("a", attributes: ["href": "/form"]) { "again" }
            }
            return context.html(title: "greetings", content: content)
        } catch ParameterError.unsupportedContentType {
            return .text("unsupported media type\n", status: .unsupportedMediaType)
        } catch {
            return .text("invalid form\n", status: .badRequest)
        }
    }
}
