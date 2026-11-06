import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"

Item {
    id: container
    width: units.gu(40)
    height: units.gu(40)

    StatCard {
        id: stat
        title: "Active Calories"
        value: "350"
        unit: "kcal"
        accentColor: "#FF5252"
        cardBgColor: "#1E1F24"
        cardBorderColor: "#2C2D32"
        textPrimaryColor: "#FFFFFF"
        textSecondaryColor: "#94A3B8"
    }

    TestCase {
        name: "StatCardTest"
        when: windowShown

        function test_initial_values() {
            compare(stat.title, "Active Calories");
            compare(stat.value, "350");
            compare(stat.unit, "kcal");
            compare(stat.accentColor, "#ff5252");
        }

        function test_value_update() {
            stat.value = "420";
            compare(stat.value, "420");

            stat.title = "Duration";
            stat.unit = "mins";
            compare(stat.title, "Duration");
            compare(stat.unit, "mins");
        }
    }
}

