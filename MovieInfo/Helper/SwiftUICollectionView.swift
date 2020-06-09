//
//  SwiftUICollectionView.swift
//  MovieInfo
//
//  Created by Breidenbach, Francis X. -ND on 6/8/20.
//  Copyright © 2020 Francis Breidenbach. All rights reserved.
//

import SwiftUI

typealias CollectionViewElementSize<Elements> = [Elements.Element.ID: CGSize] where Elements: RandomAccessCollection, Elements.Element: Identifiable

enum CollectionViewLayout {
    
    case flow
    
    func layout<Elements>(for elements: Elements, containerSize: CGSize, sizes: CollectionViewElementSize<Elements>) -> CollectionViewElementSize<Elements> {
        
        switch self {
            case .flow:
                return flowLayout(for: elements, containerSize: containerSize, sizes: sizes)
        }
    }
    
    private func flowLayout<Elements> (
        for elements: Elements,
        containerSize: CGSize,
        sizes: CollectionViewElementSize<Elements>) -> CollectionViewElementSize<Elements> {
        
        var state = FlowLayout(containerSize: containerSize)
        var result: CollectionViewElementSize<Elements> = [:]
        
        for elements in elements {
            let rect = state.add(element: sizes[element.id] ?? .zero)
            
            result[element.id] = CGSize(width: rect.origin.x, height: rect.origin.y)
        }
        
        return result
    }
    
    private struct FlowLayout {
        
        let spacing: UIOffset
        let containerSize: CGSize
        
        var current = CGPoint.zero
        var lineHeight = CGFloat.zero
        
        init(containerSize: CGSize, spacing: UIOffset = UIOffset(horizontal: 10, vertical: 10)) {
            
            self.spacing = spacing
            self.containerSize = containerSize
        }
        
        mutating func add(element size: CGSize) -> CGRect {
            
            if current.x + size.width > containerSize.width {
                current.x = 0
                current.y += lineHeight + spacing.vertical
                lineHeight = 0
            }
            
            defer {
                lineHeight = max(lineHeight, size.height)
                current.x += size.width + spacing.horizontal
            }
            
            return CGRect(origin: current, size: size)
        }
    }
}

struct SwiftUICollectionView<Elements, Content>: View where Elements: RandomAccessCollection, Content: View, Elements.Element: Identifiable {
    
    private var layout: CollectionViewLayout
    
    @State private var sizes: CollectionViewElementSize<Elements> = [:]
    
    var body: some View {
        GeometryReader { proxy in
            self.bodyFor(self.layout, containerSize: proxy.size, offsets: self.layout.layout(for: self.pagedCollection.dataDisplayed, containerSize: proxy.size, sizes: self.sizes))
        }
    }
    
    private func bodyFor(_ layout: CollectionViewLayout, containerSize: CGSize, offsets: CollectionViewElementSize<Elements>) -> some View {
        
        switch layout {
            case .flow:
                return AnyView(flowLayoutBody(containerSize: containerSize, offset: offsets))
        }
    }
}

private func flowLayoutBody(containerSize: CGSize, offsets: CollectionViewElementSize) -> some View {
    
    ZStack(alignment: .topLeading) {
        ForEach(pagedCollection.dataDisplayed) {
            PropagateSize(content: self.contentView($0).embededInNavigationLink, id: $0.id)
                .offset(offsets[$0.id] ?? CGSize.zero)
                .animation(Animation.spring())
                .onFrameChange {
                    // TODO: add stuff
            }
        }
        
        Color.clear.frame(width: containerSize.width, height: containerSize.height)
    }
    
    return ScrollView(.horizontal) {
        // TODO: implementation
    }
    .onPreferenceChange(CollectionViewSizeKey.self) {
        self.sizes = $0
    }
}

private struct PropagateSize<V: View, ID: Hashable>: View {
    
    var content: V
    var id: ID
    
    var body: some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: CollectionViewSizeKey.self, value: [self.id: proxy.size])
            }
        )
    }
}

private struct CollectionViewSizeKey<ID: Hashable>: PreferenceKey {
    
    typealias Value = [ID: CGSize]
    
    static var defaultValue: [ID : CGSize] { [:] }
    
    static func reduce(value: inout [ID : CGSize], nextValue: () -> [ID : CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
