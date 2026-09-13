import SwiftUI

struct StatusHUDView: View {
    var body: some View {
        HStack(spacing : 10){
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            
            Text("macVision Active")
                .font(.system(size:13, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: 200, height: 44)
        .background(.black, in: Capsule())
    }
}