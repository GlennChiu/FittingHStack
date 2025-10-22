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

public enum SpacingDistribution {
    /// Fixed spacing between items.
    case fixed
    /// Spacing adjusted to fill the available width.
    case fillWidth
}

/// A horizontal stack that wraps its content to fit within the available width
public struct FittingHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let spacingDistribution: SpacingDistribution
    let content: () -> Content
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        spacingDistribution: SpacingDistribution = .fixed,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.spacingDistribution = spacingDistribution
        self.content = content
    }
    
    public var body: some View {
        FittingHStackLayout(
            alignment: alignment,
            horizontalMinSpacing: spacing,
            verticalSpacing: lineSpacing,
            spacingDistribution: spacingDistribution
        ) {
            content()
        }
    }
}

private struct FittingHStackLayout: Layout {
    var alignment: VerticalAlignment
    var horizontalMinSpacing: CGFloat
    var verticalSpacing: CGFloat
    var spacingDistribution: SpacingDistribution
    
    init(
        alignment: VerticalAlignment = .center,
        horizontalMinSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        spacingDistribution: SpacingDistribution = .fixed
    ) {
        self.alignment = alignment
        self.horizontalMinSpacing = horizontalMinSpacing
        self.verticalSpacing = verticalSpacing
        self.spacingDistribution = spacingDistribution
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let result = computeLayout(for: subviews, proposal: proposal)
        cache.rows = result.rows
        cache.rowItemWidths = result.rowItemWidths
        cache.rowHeights = result.rowHeights
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        guard !subviews.isEmpty else { return }
        
        var y = bounds.minY
        
        for (rowIndex, row) in cache.rows.enumerated() {
            var x = bounds.minX
            let widths = cache.rowItemWidths[safe: rowIndex] ?? row.map { $0.sizeThatFits(.unspecified).width }
            let rowHeight = cache.rowHeights[safe: rowIndex] ?? row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            
            let gaps = max(0, row.count - 1)
            let contentWidth = widths.reduce(0, +)
            
            let interItemSpacing: CGFloat = {
                guard spacingDistribution == .fillWidth, bounds.width.isFinite, gaps > 0 else {
                    return horizontalMinSpacing
                }
                let minTotal = contentWidth + CGFloat(gaps) * horizontalMinSpacing
                let leftover = max(0, bounds.width - minTotal)
                return horizontalMinSpacing + leftover / CGFloat(gaps)
            }()
            
            for (i, subview) in row.enumerated() {
                let w = widths[safe: i] ?? subview.sizeThatFits(.unspecified).width
                let h = subview.sizeThatFits(.init(width: w, height: nil)).height
                
                let yPosition: CGFloat
                switch alignment {
                    case .top:
                        yPosition = y
                    case .bottom:
                        yPosition = y + rowHeight - h
                    default:
                        yPosition = y + (rowHeight - h) / 2
                }
                
                subview.place(at: CGPoint(x: x, y: yPosition), anchor: .topLeading, proposal: ProposedViewSize(width: w, height: h))
                
                x += w
                
                if i < row.count - 1 {
                    x += interItemSpacing
                }
            }
            
            y += rowHeight + verticalSpacing
        }
    }
    
    private func computeLayout(for subviews: Subviews, proposal: ProposedViewSize) -> (
        size: CGSize,
        rows: [[LayoutSubviews.Element]],
        rowItemWidths: [[CGFloat]],
        rowHeights: [CGFloat]
    ) {
        let availableWidth = proposal.width
        
        var rows: [[LayoutSubviews.Element]] = []
        var rowItemWidths: [[CGFloat]] = []
        var rowHeights: [CGFloat] = []
        
        var currentRow: [LayoutSubviews.Element] = []
        var currentRowWidths: [CGFloat] = []
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        func finalizeCurrentRow() {
            guard !currentRow.isEmpty else { return }
            
            rows.append(currentRow)
            rowItemWidths.append(currentRowWidths)
            rowHeights.append(currentRowHeight)
            totalHeight += (rows.count > 1 ? verticalSpacing : 0) + currentRowHeight
            currentRow = []
            currentRowWidths = []
            currentRowWidth = 0
            currentRowHeight = 0
        }
        
        for subview in subviews {
            let idealSize = subview.sizeThatFits(.unspecified)
            let measuredWidth = availableWidth.map { min(idealSize.width, $0) } ?? idealSize.width
            let measuredHeight = subview.sizeThatFits(.init(width: measuredWidth, height: nil)).height
            
            let nextWidthIfAdded = currentRowWidth + measuredWidth + (currentRow.isEmpty ? 0 : horizontalMinSpacing)
            
            if let maxWidth = availableWidth, nextWidthIfAdded > maxWidth, !currentRow.isEmpty {
                finalizeCurrentRow()
            }
            
            currentRow.append(subview)
            currentRowWidths.append(measuredWidth)
            currentRowWidth += measuredWidth + (currentRow.count > 1 ? horizontalMinSpacing : 0)
            currentRowHeight = max(currentRowHeight, measuredHeight)
        }
        
        if !currentRow.isEmpty {
            currentRowWidth -= (currentRow.count > 1 ? horizontalMinSpacing : 0)
            finalizeCurrentRow()
        }
        
        let naturalRowWidths = zip(rows, rowItemWidths).map { row, widths in
            let gaps = max(0, row.count - 1)
            return widths.reduce(0, +) + CGFloat(gaps) * horizontalMinSpacing
        }
        
        let finalWidth = availableWidth ?? (naturalRowWidths.max() ?? 0)
        
        return (CGSize(width: finalWidth, height: totalHeight), rows, rowItemWidths, rowHeights)
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    struct Cache {
        var rows: [[LayoutSubviews.Element]] = []
        var rowItemWidths: [[CGFloat]] = []
        var rowHeights: [CGFloat] = []
    }
}

extension Collection {
    fileprivate subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
