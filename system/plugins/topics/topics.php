<?php
namespace Grav\Plugin;

use Grav\Common\Grav;
use Grav\Common\Plugin;
use Grav\Framework\Flex\Interfaces\FlexInterface;
use Grav\Framework\Flex\Interfaces\FlexDirectoryInterface;

/**
 * Class TopicsPlugin
 * @package Grav\Plugin
 */
class TopicsPlugin extends Plugin
{
    /**
     * @return array
     *
     * The getSubscribedEvents() gives the core a list of events
     *     that the plugin wants to listen to. The key of each
     *     array section is the event that the plugin listens to
     *     and the value (in the form of an array) contains the
     *     callable (or function) as well as the priority. The
     *     higher the number the higher the priority.
     */
    public static function getSubscribedEvents(): array
    {
        return [
            'onPluginsInitialized' => [
                // Uncomment following line when plugin requires Grav < 1.7
                // ['autoload', 100000],
                ['onPluginsInitialized', 0]
            ]
        ];
    }

    /**
     * Initialize the plugin
     */
    public function onPluginsInitialized(): void
    {
        // Don't proceed if we are in the admin plugin
        if ($this->isAdmin()) {
            return;
        }

        // Enable the main events we are interested in
        $this->enable([
            // Put your main events here
        ]);
    }

    /**
     * Returns all available and published (published === true) topics as an array of topic IDs
     * @return (string|string)[]
     */
    public static function topics(): array
    {
      /** @var Grav */
      $grav = Grav::instance();
      $grav['admin']->enablePages();
      /** @var Page */
      $topicDirectory = $grav['flex']->getDirectory('topics');
      $topics = $topicDirectory->getCollection();

      /** @var array<string, string> */
      $children = [];
      foreach ($topics as $topic) {
        $published = $topic['published'];
        if ($published) {
          $topicId = $topic['topic_id'];
          $children[$topicId] = $topicId;
        }
      }

      return $children;
    }

    /**
     * Returns all available and published (published === true) topics as an array of 'text'-'value' pairs both containing the topic ID
     * @return array[
     *  'text' => string,
     *  'value' => string
     * ]
     */
    public static function topicsAsTextValuePair(): array
    {
      $topicIds = self::topics();

      /** @var array<array<string, string>> */
      $children = [];
      foreach ($topicIds as $topicId => $value) {
        array_push($children, ['text' => $topicId, 'value' => $topicId]);
      }

      return $children;
    }
}
