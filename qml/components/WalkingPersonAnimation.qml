import QtQuick 2.7
import Lomiri.Components 1.3

Item {
    id: rootAnim

    // Public configurable properties
    property bool running: true
    property bool isJogging: false
    property int duration: isJogging ? 720 : 1080
    property color primaryColor: (typeof root !== "undefined" && root.primaryColor) ? root.primaryColor : "#FF5252"
    property color secondaryColor: (typeof root !== "undefined" && root.secondaryColor) ? root.secondaryColor : "#FB923C"
    property bool isDarkMode: (typeof root !== "undefined" && root.isDarkMode) ? root.isDarkMode : 
                              (typeof theme !== "undefined" && theme.name === "Ubuntu.Components.Themes.SuruDark")

    width: units.gu(26)
    height: units.gu(20)

    // Palette
    readonly property color skinToneFront: "#F6C6B0"
    readonly property color skinToneBack: "#DEAB96"     // Shaded for 3D depth
    readonly property color shortsColor: isDarkMode ? "#252A34" : "#2E3440"
    readonly property color trackColor: isDarkMode ? "#3B4252" : "#D8DEE9"
    readonly property color trackDashColor: isDarkMode ? "#88C0D0" : "#5E81AC"
    readonly property color sockColor: "#FFFFFF"
    readonly property color shoeSoleColor: "#F4F5F7"

    // Continuous normalized cycle progress between 0.0 and 1.0
    property real progress: 0.0

    NumberAnimation {
        id: cycleAnimation
        target: rootAnim
        property: "progress"
        from: 0.0
        to: 1.0
        duration: rootAnim.duration
        loops: Animation.Infinite
        running: rootAnim.running && rootAnim.visible
    }

    // Kinematics calculations
    readonly property real omega: progress * 2.0 * Math.PI
    readonly property real bounceY: -Math.abs(Math.sin(omega)) * (isJogging ? units.dp(8) : units.dp(5))
    readonly property real forwardLean: isJogging ? 11.0 : 6.0

    // Leg angles
    readonly property real legSwingAmp: isJogging ? 38.0 : 25.0
    readonly property real thighAngleFront: Math.sin(omega) * legSwingAmp
    readonly property real thighAngleBack: -Math.sin(omega) * legSwingAmp

    readonly property real kneeAngleFront: Math.max(0.0, Math.sin(omega - 0.35) * (isJogging ? 62.0 : 42.0))
    readonly property real kneeAngleBack: Math.max(0.0, Math.sin(omega + Math.PI - 0.35) * (isJogging ? 62.0 : 42.0))

    readonly property real footAngleFront: -thighAngleFront * 0.35 - kneeAngleFront * 0.25
    readonly property real footAngleBack: -thighAngleBack * 0.35 - kneeAngleBack * 0.25

    // Arm angles
    readonly property real armSwingAmp: isJogging ? 36.0 : 24.0
    readonly property real armAngleFront: -Math.sin(omega) * armSwingAmp - (isJogging ? 14.0 : 8.0)
    readonly property real armAngleBack: Math.sin(omega) * armSwingAmp - (isJogging ? 14.0 : 8.0)

    readonly property real elbowAngleFront: (isJogging ? 58.0 : 36.0) + Math.sin(omega) * 10.0
    readonly property real elbowAngleBack: (isJogging ? 58.0 : 36.0) - Math.sin(omega) * 10.0

    // Ground Y position
    readonly property real groundY: height - units.gu(4.5)

    // Interactive toggle area
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            isJogging = !isJogging
        }
    }

    // ==========================================
    // LAYER 1: AMBIENT GLOW AURA (PULSING)
    // ==========================================
    Rectangle {
        id: auraGlow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -units.gu(1.5)
        width: units.gu(17)
        height: units.gu(17)
        radius: width / 2
        color: rootAnim.primaryColor
        opacity: isDarkMode ? (0.10 + Math.sin(omega) * 0.04) : (0.07 + Math.sin(omega) * 0.03)
        scale: 1.0 + Math.sin(omega) * 0.05
    }

    // Secondary subtle pulse ring
    Rectangle {
        anchors.centerIn: auraGlow
        width: auraGlow.width * 1.2
        height: width
        radius: width / 2
        color: "transparent"
        border.color: rootAnim.secondaryColor
        border.width: units.dp(1)
        opacity: isDarkMode ? (0.15 - Math.sin(omega) * 0.05) : (0.10 - Math.sin(omega) * 0.04)
        scale: 0.95 + Math.sin(omega) * 0.08
    }

    // ==========================================
    // LAYER 2: SPEED PARTICLES / AMBIENT BREEZE
    // ==========================================
    Repeater {
        model: 3
        Item {
            id: particleItem
            property real pOffset: (index * 0.33)
            property real pProgress: (rootAnim.progress + pOffset) % 1.0
            x: (rootAnim.width * 0.85) - (pProgress * rootAnim.width * 0.75)
            y: rootAnim.groundY - units.gu(2) - (index * units.gu(2.5)) + (Math.sin(pProgress * Math.PI) * units.gu(0.5))
            opacity: Math.sin(pProgress * Math.PI) * (isDarkMode ? 0.6 : 0.4)

            Rectangle {
                width: units.dp(12) + (index * units.dp(6))
                height: units.dp(2)
                radius: units.dp(1)
                color: rootAnim.secondaryColor
            }
        }
    }

    // ==========================================
    // LAYER 3: DYNAMIC MOVING GROUND TRACK (TREADMILL)
    // ==========================================
    Item {
        id: trackContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: rootAnim.groundY
        height: units.gu(1.5)

        // Main baseline track
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: units.gu(2)
            height: units.dp(2)
            color: rootAnim.trackColor
            radius: units.dp(1)
            opacity: 0.6
        }

        // Fast moving dashed speed markers
        Repeater {
            model: 5
            Rectangle {
                property real dashSpacing: (trackContainer.width - units.gu(4)) / 5
                property real dashOffset: (rootAnim.progress * dashSpacing)
                x: units.gu(2) + ((index * dashSpacing - dashOffset + (trackContainer.width - units.gu(4))) % (trackContainer.width - units.gu(4)))
                y: units.dp(5)
                width: units.dp(14)
                height: units.dp(2.5)
                radius: units.dp(1.2)
                color: rootAnim.trackDashColor
                opacity: 0.7
            }
        }
    }

    // ==========================================
    // LAYER 4: KINEMATIC CHARACTER
    // ==========================================
    Item {
        id: characterContainer
        x: (parent.width / 2) - units.dp(6)
        y: rootAnim.groundY - units.dp(106) + rootAnim.bounceY
        width: units.dp(50)
        height: units.dp(110)
        rotation: rootAnim.forwardLean
        transformOrigin: Item.Bottom

        // ------------------------------------------
        // 4A: BACK ARM (Deepest layer, swings opposite to back leg)
        // ------------------------------------------
        Item {
            id: backArm
            x: units.dp(18)
            y: units.dp(26)
            width: units.dp(9)
            height: units.dp(24)
            transformOrigin: Item.Top
            rotation: rootAnim.armAngleBack
            opacity: 0.85

            // Upper Arm / Shoulder
            Rectangle {
                width: units.dp(9)
                height: units.dp(22)
                radius: units.dp(4.5)
                color: rootAnim.skinToneBack

                // Sleeve cuff
                Rectangle {
                    width: parent.width
                    height: units.dp(8)
                    radius: units.dp(4)
                    color: Qt.darker(rootAnim.primaryColor, 1.25)
                }
            }

            // Back Forearm
            Item {
                id: backForearm
                x: units.dp(1)
                y: units.dp(18)
                width: units.dp(8)
                height: units.dp(22)
                transformOrigin: Item.Top
                rotation: rootAnim.elbowAngleBack

                Rectangle {
                    width: units.dp(7.5)
                    height: units.dp(20)
                    radius: units.dp(3.5)
                    color: rootAnim.skinToneBack
                }

                // Back Hand (relaxed running fist)
                Rectangle {
                    x: -units.dp(1)
                    y: units.dp(17)
                    width: units.dp(9)
                    height: units.dp(8)
                    radius: units.dp(4)
                    color: rootAnim.skinToneBack
                }
            }
        }

        // ------------------------------------------
        // 4B: BACK LEG (Far leg, shaded)
        // ------------------------------------------
        Item {
            id: backLeg
            x: units.dp(18)
            y: units.dp(54)
            width: units.dp(12)
            height: units.dp(30)
            transformOrigin: Item.Top
            rotation: rootAnim.thighAngleBack
            opacity: 0.88

            // Thigh
            Rectangle {
                width: units.dp(11)
                height: units.dp(28)
                radius: units.dp(5.5)
                color: rootAnim.skinToneBack

                // Shorts leg cover
                Rectangle {
                    width: parent.width
                    height: units.dp(15)
                    radius: units.dp(5)
                    color: Qt.darker(rootAnim.shortsColor, 1.2)
                }
            }

            // Back Lower Leg (Calf & Shin)
            Item {
                id: backCalf
                x: units.dp(1.5)
                y: units.dp(24)
                width: units.dp(9)
                height: units.dp(28)
                transformOrigin: Item.Top
                rotation: rootAnim.kneeAngleBack

                Rectangle {
                    width: units.dp(8)
                    height: units.dp(26)
                    radius: units.dp(4)
                    color: rootAnim.skinToneBack

                    // Athletic Sock
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: units.dp(7)
                        radius: units.dp(2)
                        color: rootAnim.sockColor
                    }
                }

                // Back Sneaker
                Item {
                    id: backShoe
                    x: -units.dp(3)
                    y: units.dp(24)
                    width: units.dp(19)
                    height: units.dp(9)
                    transformOrigin: Item.TopLeft
                    rotation: rootAnim.footAngleBack

                    // Sneaker Upper
                    Rectangle {
                        width: units.dp(18)
                        height: units.dp(7)
                        radius: units.dp(3)
                        color: Qt.darker(rootAnim.secondaryColor, 1.2)

                        // Shoe accent stripe
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: units.dp(3)
                            anchors.verticalCenter: parent.verticalCenter
                            width: units.dp(4)
                            height: units.dp(2)
                            color: "#FFFFFF"
                        }
                    }

                    // Sneaker White Sole
                    Rectangle {
                        y: units.dp(5.5)
                        width: units.dp(19)
                        height: units.dp(3.5)
                        radius: units.dp(1.5)
                        color: rootAnim.shoeSoleColor
                    }
                }
            }
        }

        // ------------------------------------------
        // 4C: TORSO & GYM WEAR
        // ------------------------------------------
        Item {
            id: torso
            x: units.dp(12)
            y: units.dp(22)
            width: units.dp(25)
            height: units.dp(36)

            // Athletic Tank Top / Shirt
            Rectangle {
                width: units.dp(23)
                height: units.dp(34)
                radius: units.dp(7)
                color: rootAnim.primaryColor

                // Aerodynamic chest accent stripe
                Rectangle {
                    x: units.dp(4)
                    y: units.dp(12)
                    width: units.dp(15)
                    height: units.dp(3)
                    radius: units.dp(1.5)
                    color: "#FFFFFF"
                    opacity: 0.85
                }

                // Subtle fitness lightning/energy icon badge
                Rectangle {
                    x: units.dp(7)
                    y: units.dp(19)
                    width: units.dp(9)
                    height: units.dp(2)
                    radius: units.dp(1)
                    color: rootAnim.secondaryColor
                    opacity: 0.9
                }
            }

            // Athletic Gym Shorts
            Rectangle {
                y: units.dp(28)
                width: units.dp(24)
                height: units.dp(13)
                radius: units.dp(4)
                color: rootAnim.shortsColor

                // Sporty waistband stripe
                Rectangle {
                    width: parent.width
                    height: units.dp(2.5)
                    radius: units.dp(1)
                    color: rootAnim.secondaryColor
                    opacity: 0.9
                }
            }
        }

        // ------------------------------------------
        // 4D: HEAD, CAP & WIRELESS EARBUD
        // ------------------------------------------
        Item {
            id: headContainer
            x: units.dp(16)
            y: units.dp(0)
            width: units.dp(24)
            height: units.dp(25)

            // Neck
            Rectangle {
                x: units.dp(5)
                y: units.dp(16)
                width: units.dp(8)
                height: units.dp(9)
                radius: units.dp(3)
                color: rootAnim.skinToneFront
            }

            // Head (circle)
            Rectangle {
                x: units.dp(1)
                y: units.dp(2)
                width: units.dp(21)
                height: units.dp(21)
                radius: width / 2
                color: rootAnim.skinToneFront

                // Athletic Cap / Hair
                Rectangle {
                    width: parent.width
                    height: units.dp(12)
                    radius: units.dp(6)
                    color: isDarkMode ? "#1A1D24" : "#2B2D42"

                    // Cap Visor (pointing right into movement)
                    Rectangle {
                        x: units.dp(12)
                        y: units.dp(7)
                        width: units.dp(11)
                        height: units.dp(3.5)
                        radius: units.dp(1.5)
                        color: isDarkMode ? "#1A1D24" : "#2B2D42"
                    }

                    // Sporty Cap Accent Band
                    Rectangle {
                        y: units.dp(8)
                        width: parent.width + units.dp(2)
                        height: units.dp(2)
                        color: rootAnim.secondaryColor
                    }
                }

                // Wireless Sports Earbud
                Rectangle {
                    x: units.dp(7)
                    y: units.dp(12)
                    width: units.dp(3.5)
                    height: units.dp(3.5)
                    radius: width / 2
                    color: "#FFFFFF"
                    border.color: "#38BDF8"
                    border.width: units.dp(0.5)
                }
            }
        }

        // ------------------------------------------
        // 4E: FRONT LEG (Near camera, fully detailed)
        // ------------------------------------------
        Item {
            id: frontLeg
            x: units.dp(20)
            y: units.dp(54)
            width: units.dp(12)
            height: units.dp(30)
            transformOrigin: Item.Top
            rotation: rootAnim.thighAngleFront

            // Thigh
            Rectangle {
                width: units.dp(11.5)
                height: units.dp(28)
                radius: units.dp(5.5)
                color: rootAnim.skinToneFront

                // Shorts leg cover
                Rectangle {
                    width: parent.width
                    height: units.dp(15)
                    radius: units.dp(5)
                    color: rootAnim.shortsColor

                    // Side stripe on shorts
                    Rectangle {
                        x: units.dp(8)
                        width: units.dp(2)
                        height: parent.height
                        color: "#FFFFFF"
                        opacity: 0.8
                    }
                }
            }

            // Front Lower Leg (Calf & Shin)
            Item {
                id: frontCalf
                x: units.dp(1.5)
                y: units.dp(24)
                width: units.dp(9)
                height: units.dp(28)
                transformOrigin: Item.Top
                rotation: rootAnim.kneeAngleFront

                Rectangle {
                    width: units.dp(8.5)
                    height: units.dp(26)
                    radius: units.dp(4)
                    color: rootAnim.skinToneFront

                    // Athletic Sock
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: units.dp(7.5)
                        radius: units.dp(2)
                        color: rootAnim.sockColor
                    }
                }

                // Front Sneaker
                Item {
                    id: frontShoe
                    x: -units.dp(3)
                    y: units.dp(24)
                    width: units.dp(20)
                    height: units.dp(10)
                    transformOrigin: Item.TopLeft
                    rotation: rootAnim.footAngleFront

                    // Sneaker Upper
                    Rectangle {
                        width: units.dp(19)
                        height: units.dp(7.5)
                        radius: units.dp(3.5)
                        color: rootAnim.primaryColor

                        // White athletic stripe
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: units.dp(3.5)
                            anchors.verticalCenter: parent.verticalCenter
                            width: units.dp(4.5)
                            height: units.dp(2.2)
                            radius: units.dp(1)
                            color: "#FFFFFF"
                        }
                    }

                    // Sneaker White Sole (aerodynamic running foam)
                    Rectangle {
                        y: units.dp(6)
                        width: units.dp(20)
                        height: units.dp(4)
                        radius: units.dp(1.8)
                        color: rootAnim.shoeSoleColor
                    }
                }
            }
        }

        // ------------------------------------------
        // 4F: FRONT ARM (Nearest layer, with Smart Fitness Watch)
        // ------------------------------------------
        Item {
            id: frontArm
            x: units.dp(24)
            y: units.dp(26)
            width: units.dp(9)
            height: units.dp(24)
            transformOrigin: Item.Top
            rotation: rootAnim.armAngleFront

            // Upper Arm / Shoulder
            Rectangle {
                width: units.dp(9)
                height: units.dp(22)
                radius: units.dp(4.5)
                color: rootAnim.skinToneFront

                // Sleeve cuff
                Rectangle {
                    width: parent.width
                    height: units.dp(8)
                    radius: units.dp(4)
                    color: rootAnim.primaryColor
                }
            }

            // Front Forearm
            Item {
                id: frontForearm
                x: units.dp(1)
                y: units.dp(18)
                width: units.dp(8)
                height: units.dp(22)
                transformOrigin: Item.Top
                rotation: rootAnim.elbowAngleFront

                Rectangle {
                    width: units.dp(8)
                    height: units.dp(20)
                    radius: units.dp(4)
                    color: rootAnim.skinToneFront

                    // SMART FITNESS WATCH on wrist!
                    Rectangle {
                        x: -units.dp(0.5)
                        y: units.dp(11)
                        width: units.dp(9)
                        height: units.dp(4.5)
                        radius: units.dp(2)
                        color: "#1E222A"

                        // Active Glowing Watch Display (Cyan/Emerald)
                        Rectangle {
                            anchors.centerIn: parent
                            width: units.dp(3)
                            height: units.dp(2.5)
                            radius: units.dp(1)
                            color: "#10B981"
                        }
                    }
                }

                // Front Hand (relaxed running fist)
                Rectangle {
                    x: -units.dp(1)
                    y: units.dp(17)
                    width: units.dp(9.5)
                    height: units.dp(8.5)
                    radius: units.dp(4)
                    color: rootAnim.skinToneFront
                }
            }
        }
    }

}
