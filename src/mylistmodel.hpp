/*
 * MyListModel.h
 * Data model for the video list view
 */

#ifndef MyListModel_HPP_
#define MyListModel_HPP_

#include <QObject>
#include <QString>
#include <QVariant>
#include <QMetaType>
#include <bb/cascades/QListDataModel>


/*
 * Mutable list model implementation
 */
class MyListModel : public bb::cascades::QVariantListDataModel
{
    Q_OBJECT
public:

    /*
     * Convenience method for loading data from JSON file.
     *
     * @param file_name  file to load
     */
    Q_INVOKABLE void load();

    Q_INVOKABLE void saveData();

    /*
     * Convenience method to read the model data.
     *
     * @param ix  index of the list item
     * @param fld_name  name of data field
     */
    Q_INVOKABLE QVariant value(int ix, const QString &fld_name);

    /*
     * Convenience method to set the model data.
     *
     * @param ix  index of the list item
     * @param fld_name  name of data field
     * @param val  new value
     */
    Q_INVOKABLE void setValue(int ix, const QString &fld_name, const QVariant &val);

    /*
     * Method to set the selected index when the list selection was changed by user.
     *
     * @param index The selected item's index
     */
    Q_INVOKABLE void setSelectedIndex(int index);

    /*
     * Gets the path of the video which was selected by user.
     */
    Q_INVOKABLE QString getSelectedVideoPath();

    /*
     * Gets the path of the next video.
     */
    Q_INVOKABLE QString getNextVideoPath(void);

    /*
     * Gets the path of the previous video.
     */
    Q_INVOKABLE QString getPreviousVideoPath(void);

    /*
     * Converts the specified amount of milliseconds to a formatted time (hh:mm:ss).
     *
     * @param msecs The amount of milliseconds to be converted.
     * @TODO Move this function to some utility class.
     */
    Q_INVOKABLE QString getFormattedTime(int msecs);

    Q_INVOKABLE void setVideoPosition(int);

    Q_INVOKABLE int getVideoPosition();

public:
    MyListModel(QObject* parent = 0);
    virtual ~MyListModel();

private:
    int m_selectedIndex;
    QVariantList m_list;
    QString m_file;
};


#endif /* MyListModel_HPP_ */
