//
//  This code is distributed under the terms and conditions of the MIT license.
//
//  Copyright (c) 2025 Glenn Chiu
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SwiftUI

public struct FittingHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: () -> Content
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }
    
    public var body: some View {
        FittingHStackLayout(
            alignment: alignment,
            horizontalSpacing: spacing,
            verticalSpacing: lineSpacing
        ) {
            content()
        }
    }
}

private struct FittingHStackLayout: Layout {
    var alignment: VerticalAlignment
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat
    
    init(
        alignment: VerticalAlignment = .center, horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8
    ) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize
    {
        let result = computeLayout(for: subviews, proposal: proposal)
        cache.rows = result.rows
        return result.size
    }
    
    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache
    ) {
        guard !subviews.isEmpty else { return }
        
        var y = bounds.minY
        
        for row in cache.rows {
            var x = bounds.minX
            let rowHeight =
            row.map { $0.sizeThatFits(.init(width: bounds.width, height: nil)).height }.max()
            ?? 0
            
            for subview in row {
                let subviewSize = subview.sizeThatFits(.init(width: bounds.width, height: nil))
                
                let yPosition: CGFloat
                switch alignment {
                    case .top:
                        yPosition = y
                    case .bottom:
                        yPosition = y + rowHeight - subviewSize.height
                    default:  // .center
                        yPosition = y + (rowHeight - subviewSize.height) / 2
                }
                
                let placementProposal = ProposedViewSize(
                    width: subviewSize.width, height: subviewSize.height)
                subview.place(
                    at: CGPoint(x: x, y: yPosition), anchor: .topLeading,
                    proposal: placementProposal)
                x += subviewSize.width + horizontalSpacing
            }
            y += rowHeight + verticalSpacing
        }
    }
    
    private func computeLayout(for subviews: Subviews, proposal: ProposedViewSize) -> (
        size: CGSize, rows: [[LayoutSubviews.Element]]
    ) {
        let containerWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.init(width: containerWidth, height: nil))
            
            if currentRowWidth + subviewSize.width + (!currentRow.isEmpty ? horizontalSpacing : 0)
                > containerWidth
            {
                totalHeight += currentRowHeight
                if !rows.isEmpty {
                    totalHeight += verticalSpacing
                }
                rows.append(currentRow)
                currentRow = []
                currentRowWidth = 0
                currentRowHeight = 0
            }
            
            currentRow.append(subview)
            currentRowWidth += subviewSize.width
            if !currentRow.isEmpty {
                currentRowWidth += horizontalSpacing
            }
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }
        
        if !currentRow.isEmpty {
            totalHeight += currentRowHeight
            if !rows.isEmpty {
                totalHeight += verticalSpacing
            }
            rows.append(currentRow)
        }
        
        let finalWidth =
        proposal.width ?? rows.map { row in
            let subviewsWidth = row.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width }
            let spacing = CGFloat(max(0, row.count - 1)) * horizontalSpacing
            return subviewsWidth + spacing
        }.max() ?? 0
        
        return (CGSize(width: finalWidth, height: totalHeight), rows)
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    struct Cache {
        var rows: [[LayoutSubviews.Element]] = []
    }
}
