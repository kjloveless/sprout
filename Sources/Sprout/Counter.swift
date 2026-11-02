import Foundation

struct CounterProps: Encodable {
    let initial: Int
}

func makeCounter(initial: Int) throws -> HTMLNode {
    let data = try JSONEncoder().encode(CounterProps(initial: initial))
    let props = String(decoding: data, as: UTF8.self)

    return .island(name: "counter", props: props, children: [
        .element("p", [:], [
            .text("count: "),
            .element("span", ["data-count": ""], [.text(String(initial))])
        ]),
        .element("button", ["type": "button", "data-add": ""], [
            .text("add one")
        ])
    ])
}
