import AppKit
import SwiftUI

struct MacVerticalScrollView<Content: View>: NSViewRepresentable {
var bottomInset: CGFloat = 160
@ViewBuilder var content: () -> Content

func makeNSView(context: Context) -> NSScrollView {
  let scrollView = NSScrollView()
  scrollView.drawsBackground = false
  scrollView.hasVerticalScroller = true
  scrollView.hasHorizontalScroller = false
  scrollView.autohidesScrollers = false
  scrollView.scrollerStyle = .legacy
  scrollView.borderType = .noBorder

  let hostingView = NSHostingView(rootView: content())
  hostingView.translatesAutoresizingMaskIntoConstraints = true
  scrollView.documentView = hostingView

  context.coordinator.scrollView = scrollView
  context.coordinator.hostingView = hostingView
  context.coordinator.bottomInset = bottomInset
  context.coordinator.scheduleReflow()

  return scrollView
}

func updateNSView(_ scrollView: NSScrollView, context: Context) {
  context.coordinator.bottomInset = bottomInset
  context.coordinator.hostingView?.rootView = content()
  context.coordinator.scheduleReflow()
}

func makeCoordinator() -> Coordinator { Coordinator() }

final class Coordinator {
  weak var scrollView: NSScrollView?
  var hostingView: NSHostingView<Content>?
  var bottomInset: CGFloat = 160
  private var reflowWorkItem: DispatchWorkItem?
  private var lastAppliedSize = NSSize.zero

  func scheduleReflow() {
    reflowWorkItem?.cancel()
    let work = DispatchWorkItem { [weak self] in self?.reflowDocument() }
    reflowWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02, execute: work)
  }

  func reflowDocument() {
    guard let scrollView, let hostingView else { return }

    let width = max(scrollView.contentView.bounds.width, scrollView.bounds.width, 320)
    let proposed = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)

    hostingView.setFrameSize(NSSize(width: width, height: 1))
    let measured = hostingView.fittingSize
    let height = max(measured.height, 1) + bottomInset
    let target = NSSize(width: width, height: height)

    if abs(target.width - lastAppliedSize.width) < 0.5,
     abs(target.height - lastAppliedSize.height) < 0.5 {
      return
    }
    lastAppliedSize = target
    hostingView.setFrameSize(target)
  }
}
}

